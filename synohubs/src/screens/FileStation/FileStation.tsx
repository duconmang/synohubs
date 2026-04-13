import React, { useEffect, useState, useCallback, useRef } from 'react';
import { invoke } from '@tauri-apps/api/core';
import {
  FolderOpen, ChevronRight, ArrowLeft, RefreshCw,
  Plus, Trash2, Pencil, Download, X, Home,
  FileText, FileImage, FileVideo, FileAudio, FileArchive, FileCode,
  Copy, Scissors, ClipboardPaste, Share2, QrCode, Info, FolderPlus,
  Archive, Link
} from 'lucide-react';
import { useConfirmDialog } from '../../components/ConfirmDialog/ConfirmDialog';
import './FileStation.css';

interface FileItem {
  path: string;
  name: string;
  isdir: boolean;
  additional?: {
    size?: number;
    time?: { mtime?: number; crtime?: number };
    type?: string;
    owner?: { user?: string };
    perm?: { acl?: { append?: boolean; del?: boolean; exec?: boolean; read?: boolean; write?: boolean } };
  };
}

interface ContextMenuState {
  visible: boolean;
  x: number;
  y: number;
  item: FileItem | null;    // null = right-clicked on empty space
}

const FileStation: React.FC = () => {
  const [currentPath, setCurrentPath] = useState<string>('');
  const [files, setFiles] = useState<FileItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Actions state
  const [showNewFolder, setShowNewFolder] = useState(false);
  const [newFolderName, setNewFolderName] = useState('');
  const [renamingPath, setRenamingPath] = useState<string | null>(null);
  const [renameValue, setRenameValue] = useState('');
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [total, setTotal] = useState(0);

  // Clipboard for copy/cut
  const [clipboard, setClipboard] = useState<{ paths: string[]; mode: 'copy' | 'cut' } | null>(null);

  // Context menu
  const [ctxMenu, setCtxMenu] = useState<ContextMenuState>({ visible: false, x: 0, y: 0, item: null });
  const ctxRef = useRef<HTMLDivElement>(null);

  // QR / Share modal
  const [shareModal, setShareModal] = useState<{ url: string; name: string } | null>(null);

  // Custom confirm dialog
  const { showDialog, DialogComponent } = useConfirmDialog();

  // Properties modal
  const [propsModal, setPropsModal] = useState<any | null>(null);

  // ── API Calls ──

  const loadShares = useCallback(async () => {
    setLoading(true); setError(null);
    try {
      const resp: any = await invoke('file_list_shares');
      if (resp.success && resp.data?.shares) {
        setFiles(resp.data.shares);
        setTotal(resp.data.total || resp.data.shares.length);
      } else { setError(resp.error?.errors?.[0]?.code || 'Failed to list shares'); }
    } catch (err: any) { setError(err?.toString() || 'Connection error'); }
    finally { setLoading(false); }
  }, []);

  const loadFiles = useCallback(async (path: string) => {
    setLoading(true); setError(null);
    try {
      const resp: any = await invoke('file_list', { request: { folder_path: path } });
      if (resp.success && resp.data?.files) {
        setFiles(resp.data.files);
        setTotal(resp.data.total || resp.data.files.length);
      } else { setError('Failed to list files'); setFiles([]); }
    } catch (err: any) { setError(err?.toString()); setFiles([]); }
    finally { setLoading(false); }
  }, []);

  const navigateTo = useCallback((path: string) => {
    setCurrentPath(path);
    setSelected(new Set());
    setRenamingPath(null);
    setShowNewFolder(false);
    closeCtxMenu();
    if (!path) loadShares(); else loadFiles(path);
  }, [loadShares, loadFiles]);

  useEffect(() => { loadShares(); }, [loadShares]);

  const goUp = () => {
    if (!currentPath) return;
    const parts = currentPath.split('/');
    parts.pop();
    const parent = parts.join('/');
    if (parts.length <= 1) navigateTo(''); else navigateTo(parent);
  };

  const handleItemClick = (item: FileItem) => {
    if (renamingPath) return;
    if (item.isdir) navigateTo(item.path);
  };

  const handleCreateFolder = async () => {
    if (!newFolderName.trim() || !currentPath) return;
    try {
      await invoke('file_create_folder', { request: { folder_path: currentPath, name: newFolderName.trim() } });
      setShowNewFolder(false); setNewFolderName('');
      loadFiles(currentPath);
    } catch (err: any) { setError(err?.toString()); }
  };

  const handleRename = async (path: string) => {
    if (!renameValue.trim()) return;
    try {
      await invoke('file_rename', { request: { path, name: renameValue.trim() } });
      setRenamingPath(null);
      currentPath ? loadFiles(currentPath) : loadShares();
    } catch (err: any) { setError(err?.toString()); }
  };

  const handleDelete = async (paths?: string[]) => {
    const toDelete = paths || Array.from(selected);
    if (toDelete.length === 0) return;
    const confirmed = await showDialog({
      title: `Delete ${toDelete.length} item${toDelete.length > 1 ? 's' : ''}?`,
      message: 'This action cannot be undone. The selected items will be permanently removed from your NAS.',
      variant: 'danger',
      confirmText: 'Delete',
    });
    if (!confirmed) return;
    try {
      await invoke('file_delete', { request: { paths: toDelete } });
      setSelected(new Set());
      currentPath ? loadFiles(currentPath) : loadShares();
    } catch (err: any) { setError(err?.toString()); }
  };

  const handleDownload = async (path: string) => {
    try {
      const url: string = await invoke('file_download_url', { path });
      window.open(url, '_blank');
    } catch (err: any) { setError(err?.toString()); }
  };

  const handleCopy = (paths: string[]) => {
    setClipboard({ paths, mode: 'copy' });
  };

  const handleCut = (paths: string[]) => {
    setClipboard({ paths, mode: 'cut' });
  };

  const handlePaste = async () => {
    if (!clipboard || !currentPath) return;
    try {
      await invoke('file_copy_move', {
        request: {
          paths: clipboard.paths,
          dest_folder: currentPath,
          overwrite: false,
          remove_src: clipboard.mode === 'cut',
        }
      });
      if (clipboard.mode === 'cut') setClipboard(null);
      loadFiles(currentPath);
    } catch (err: any) { setError(err?.toString()); }
  };

  const handleShare = async (path: string, name: string) => {
    try {
      const resp: any = await invoke('file_share_link', { path });
      if (resp.success && resp.data?.links?.[0]?.url) {
        setShareModal({ url: resp.data.links[0].url, name });
      } else {
        // Fallback: generate download URL
        const url: string = await invoke('file_download_url', { path });
        setShareModal({ url, name });
      }
    } catch {
      // Fallback to download URL
      try {
        const url: string = await invoke('file_download_url', { path });
        setShareModal({ url, name });
      } catch (err: any) { setError(err?.toString()); }
    }
  };

  const handleCompress = async (paths: string[]) => {
    if (paths.length === 0 || !currentPath) return;
    const firstName = paths[0].split('/').pop() || 'archive';
    const destPath = `${currentPath}/${firstName}.zip`;
    try {
      await invoke('file_compress', { request: { paths, dest_file_path: destPath } });
      setTimeout(() => loadFiles(currentPath), 1500); // Wait for compression
    } catch (err: any) { setError(err?.toString()); }
  };

  const handleProperties = async (paths: string[]) => {
    try {
      const resp: any = await invoke('file_get_info', { paths });
      if (resp.success && resp.data?.files?.[0]) {
        setPropsModal(resp.data.files[0]);
      }
    } catch (err: any) { setError(err?.toString()); }
  };

  // ── Select ──

  const toggleSelect = (e: React.MouseEvent, path: string) => {
    e.stopPropagation();
    setSelected(prev => {
      const next = new Set(prev);
      if (next.has(path)) next.delete(path); else next.add(path);
      return next;
    });
  };

  // ── Context Menu ──

  const closeCtxMenu = () => setCtxMenu({ visible: false, x: 0, y: 0, item: null });

  const handleContextMenu = (e: React.MouseEvent, item: FileItem | null) => {
    e.preventDefault();
    e.stopPropagation();

    // If item is right-clicked and not in selection, select only that item
    if (item && !selected.has(item.path)) {
      setSelected(new Set([item.path]));
    }

    // Position the menu (adjust for viewport bounds)
    const x = Math.min(e.clientX, window.innerWidth - 240);
    const y = Math.min(e.clientY, window.innerHeight - 400);
    setCtxMenu({ visible: true, x, y, item });
  };

  // Close on click outside
  useEffect(() => {
    const handler = () => closeCtxMenu();
    if (ctxMenu.visible) {
      document.addEventListener('click', handler);
      return () => document.removeEventListener('click', handler);
    }
  }, [ctxMenu.visible]);

  // ── Breadcrumbs ──
  const breadcrumbs = currentPath
    ? currentPath.split('/').filter(Boolean).reduce<{ name: string; path: string }[]>((acc, part) => {
        const prevPath = acc.length > 0 ? acc[acc.length - 1].path : '';
        acc.push({ name: part, path: `${prevPath}/${part}` });
        return acc;
      }, [])
    : [];

  // Get context menu items based on what was clicked
  const getContextActions = () => {
    const item = ctxMenu.item;
    const selPaths = selected.size > 0 ? Array.from(selected) : (item ? [item.path] : []);
    const isMulti = selPaths.length > 1;
    const isFile = item && !item.isdir;

    const actions: { icon: React.ReactNode; label: string; onClick: () => void; danger?: boolean; disabled?: boolean; divider?: boolean }[] = [];

    // Download (files only)
    if (isFile && !isMulti) {
      actions.push({ icon: <Download size={16} />, label: 'Download', onClick: () => handleDownload(item!.path) });
    }

    // Create Folder (always when in a folder)
    if (currentPath) {
      actions.push({ icon: <FolderPlus size={16} />, label: 'Create Folder', onClick: () => { setShowNewFolder(true); setNewFolderName(''); }, divider: true });
    }

    // Compress
    if (selPaths.length > 0 && currentPath) {
      actions.push({ icon: <Archive size={16} />, label: isMulti ? `Compress ${selPaths.length} items` : `Compress to ${item?.name}.zip`, onClick: () => handleCompress(selPaths) });
    }

    // Copy / Cut
    if (selPaths.length > 0) {
      actions.push({ icon: <Copy size={16} />, label: isMulti ? `Copy ${selPaths.length} items` : 'Copy', onClick: () => handleCopy(selPaths), divider: true });
      actions.push({ icon: <Scissors size={16} />, label: isMulti ? `Cut ${selPaths.length} items` : 'Cut', onClick: () => handleCut(selPaths) });
    }

    // Paste
    if (clipboard && currentPath) {
      actions.push({ icon: <ClipboardPaste size={16} />, label: `Paste (${clipboard.paths.length} item${clipboard.paths.length > 1 ? 's' : ''})`, onClick: handlePaste });
    }

    // Delete
    if (selPaths.length > 0) {
      actions.push({ icon: <Trash2 size={16} />, label: isMulti ? `Delete ${selPaths.length} items` : 'Delete', onClick: () => handleDelete(selPaths), danger: true, divider: true });
    }

    // Rename (single item only)
    if (item && !isMulti) {
      actions.push({ icon: <Pencil size={16} />, label: 'Rename', onClick: () => { setRenamingPath(item.path); setRenameValue(item.name); } });
    }

    // Share / QR
    if (item && !isMulti) {
      actions.push({ icon: <Share2 size={16} />, label: 'Share Link', onClick: () => handleShare(item.path, item.name), divider: true });
      actions.push({ icon: <QrCode size={16} />, label: 'QR Code Share', onClick: () => handleShare(item.path, item.name) });
    }

    // Properties
    if (item && !isMulti) {
      actions.push({ icon: <Info size={16} />, label: 'Properties', onClick: () => handleProperties([item.path]), divider: true });
    }

    return actions;
  };

  return (
    <div className="filestation" onContextMenu={(e) => handleContextMenu(e, null)}>
      {/* Toolbar */}
      <div className="filestation__toolbar">
        <button className="btn btn-ghost btn-icon" onClick={goUp} disabled={!currentPath} title="Go up">
          <ArrowLeft size={15} />
        </button>
        <button className="btn btn-ghost btn-icon" onClick={() => navigateTo('')} title="Root">
          <Home size={15} />
        </button>

        <div className="filestation__breadcrumb">
          <span className="filestation__breadcrumb-item filestation__breadcrumb-root" onClick={() => navigateTo('')}>
            Shared Folders
          </span>
          {breadcrumbs.map((bc, i) => (
            <React.Fragment key={bc.path}>
              <ChevronRight size={12} className="filestation__breadcrumb-sep" />
              <span
                className={`filestation__breadcrumb-item ${i === breadcrumbs.length - 1 ? 'active' : ''}`}
                onClick={() => navigateTo(bc.path)}
              >
                {bc.name}
              </span>
            </React.Fragment>
          ))}
        </div>

        <div className="filestation__toolbar-spacer" />

        {currentPath && (
          <>
            <button className="btn btn-ghost btn-sm" onClick={() => { setShowNewFolder(true); setNewFolderName(''); }} title="New folder">
              <Plus size={14} /><span>New Folder</span>
            </button>
            {clipboard && (
              <button className="btn btn-ghost btn-sm btn-accent" onClick={handlePaste} title="Paste">
                <ClipboardPaste size={14} /><span>Paste ({clipboard.paths.length})</span>
              </button>
            )}
            {selected.size > 0 && (
              <button className="btn btn-ghost btn-sm btn-danger" onClick={() => handleDelete()} title="Delete selected">
                <Trash2 size={14} /><span>Delete ({selected.size})</span>
              </button>
            )}
          </>
        )}
        <button className="btn btn-ghost btn-icon" onClick={() => currentPath ? loadFiles(currentPath) : loadShares()} title="Refresh">
          <RefreshCw size={14} className={loading ? 'animate-spin' : ''} />
        </button>
      </div>

      {/* Error */}
      {error && (
        <div className="filestation__error">
          {error}
          <button onClick={() => setError(null)}><X size={12} /></button>
        </div>
      )}

      {/* New folder inline */}
      {showNewFolder && (
        <div className="filestation__new-folder">
          <FolderOpen size={16} className="filestation__new-folder-icon" />
          <input
            value={newFolderName}
            onChange={(e) => setNewFolderName(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') handleCreateFolder();
              if (e.key === 'Escape') setShowNewFolder(false);
            }}
            placeholder="Folder name..."
            autoFocus
          />
          <button className="btn btn-primary btn-sm" onClick={handleCreateFolder}>Create</button>
          <button className="btn btn-ghost btn-sm" onClick={() => setShowNewFolder(false)}>Cancel</button>
        </div>
      )}

      {/* File list */}
      <div className="filestation__list">
        <div className="filestation__list-header">
          <div className="filestation__col-check" />
          <div className="filestation__col-icon" />
          <div className="filestation__col-name">Name</div>
          <div className="filestation__col-size">Size</div>
          <div className="filestation__col-modified">Modified</div>
          <div className="filestation__col-owner">Owner</div>
          <div className="filestation__col-actions" />
        </div>

        <div className="filestation__items">
          {loading && files.length === 0 && (
            <div className="filestation__empty">Loading...</div>
          )}
          {!loading && files.length === 0 && (
            <div className="filestation__empty">
              {currentPath ? 'Empty folder' : 'No shared folders'}
            </div>
          )}
          {files.map((item) => {
            const isSelected = selected.has(item.path);
            const isCut = clipboard?.mode === 'cut' && clipboard.paths.includes(item.path);
            const size = item.additional?.size || 0;
            const mtime = item.additional?.time?.mtime;
            const owner = item.additional?.owner?.user || '—';

            return (
              <div
                key={item.path}
                className={`filestation__item ${isSelected ? 'filestation__item--selected' : ''} ${isCut ? 'filestation__item--cut' : ''}`}
                onClick={() => handleItemClick(item)}
                onDoubleClick={() => { if (!item.isdir) handleDownload(item.path); }}
                onContextMenu={(e) => handleContextMenu(e, item)}
              >
                <div className="filestation__col-check">
                  <input type="checkbox" checked={isSelected} onChange={() => {}} onClick={(e) => toggleSelect(e, item.path)} />
                </div>
                <div className="filestation__col-icon">
                  {item.isdir ? (
                    <FolderOpen size={18} className="filestation__icon-folder" />
                  ) : (
                    <FileIcon name={item.name} />
                  )}
                </div>
                <div className="filestation__col-name">
                  {renamingPath === item.path ? (
                    <div className="filestation__rename-input">
                      <input
                        value={renameValue}
                        onChange={(e) => setRenameValue(e.target.value)}
                        onKeyDown={(e) => {
                          if (e.key === 'Enter') handleRename(item.path);
                          if (e.key === 'Escape') setRenamingPath(null);
                        }}
                        onBlur={() => handleRename(item.path)}
                        autoFocus
                        onClick={(e) => e.stopPropagation()}
                      />
                    </div>
                  ) : (
                    <span className="filestation__item-name">{item.name}</span>
                  )}
                </div>
                <div className="filestation__col-size">{item.isdir ? '—' : formatFileSize(size)}</div>
                <div className="filestation__col-modified">{mtime ? formatDate(mtime) : '—'}</div>
                <div className="filestation__col-owner">{owner}</div>
                <div className="filestation__col-actions">
                  {!item.isdir && (
                    <button
                      className="btn btn-ghost btn-action-icon btn-action-download"
                      onClick={(e) => { e.stopPropagation(); handleDownload(item.path); }}
                      title="Download"
                    >
                      <Download size={15} />
                    </button>
                  )}
                  <button
                    className="btn btn-ghost btn-action-icon btn-action-rename"
                    onClick={(e) => {
                      e.stopPropagation();
                      setRenamingPath(item.path);
                      setRenameValue(item.name);
                    }}
                    title="Rename"
                  >
                    <Pencil size={15} />
                  </button>
                  <button
                    className="btn btn-ghost btn-action-icon btn-action-share"
                    onClick={(e) => { e.stopPropagation(); handleShare(item.path, item.name); }}
                    title="Share / QR"
                  >
                    <QrCode size={15} />
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Status bar */}
      <div className="filestation__statusbar">
        <span>{total} items</span>
        {selected.size > 0 && <span>{selected.size} selected</span>}
        {clipboard && <span className="filestation__statusbar-clipboard">📋 {clipboard.paths.length} {clipboard.mode === 'cut' ? 'cut' : 'copied'}</span>}
        <span className="filestation__statusbar-path">{currentPath || '/'}</span>
      </div>

      {/* ── Context Menu ── */}
      {ctxMenu.visible && (
        <div
          ref={ctxRef}
          className="ctx-menu"
          style={{ left: ctxMenu.x, top: ctxMenu.y }}
          onClick={(e) => e.stopPropagation()}
        >
          {getContextActions().map((action, i) => (
            <React.Fragment key={i}>
              {action.divider && i > 0 && <div className="ctx-menu__divider" />}
              <button
                className={`ctx-menu__item ${action.danger ? 'ctx-menu__item--danger' : ''} ${action.disabled ? 'ctx-menu__item--disabled' : ''}`}
                onClick={() => { action.onClick(); closeCtxMenu(); }}
                disabled={action.disabled}
              >
                <span className="ctx-menu__icon">{action.icon}</span>
                <span className="ctx-menu__label">{action.label}</span>
              </button>
            </React.Fragment>
          ))}
          {getContextActions().length === 0 && (
            <div className="ctx-menu__empty">No actions available</div>
          )}
        </div>
      )}

      {/* ── Share / QR Modal ── */}
      {shareModal && (
        <div className="share-modal__overlay" onClick={() => setShareModal(null)}>
          <div className="share-modal" onClick={(e) => e.stopPropagation()}>
            <div className="share-modal__header">
              <h3><Share2 size={16} /> Share: {shareModal.name}</h3>
              <button className="share-modal__close" onClick={() => setShareModal(null)}><X size={16} /></button>
            </div>
            <div className="share-modal__body">
              {/* QR Code */}
              <div className="share-modal__qr">
                <img
                  src={`https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${encodeURIComponent(shareModal.url)}&bgcolor=0d1117&color=22C55E`}
                  alt="QR Code"
                  width={200}
                  height={200}
                />
              </div>
              <p className="share-modal__hint">Scan to download</p>
              {/* Link */}
              <div className="share-modal__link-row">
                <input className="share-modal__link" value={shareModal.url} readOnly onClick={(e) => (e.target as HTMLInputElement).select()} />
                <button className="btn btn-primary btn-sm" onClick={() => {
                  navigator.clipboard.writeText(shareModal.url);
                }}>
                  <Link size={14} /> Copy
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ── Properties Modal ── */}
      {propsModal && (
        <div className="share-modal__overlay" onClick={() => setPropsModal(null)}>
          <div className="share-modal" onClick={(e) => e.stopPropagation()}>
            <div className="share-modal__header">
              <h3><Info size={16} /> Properties</h3>
              <button className="share-modal__close" onClick={() => setPropsModal(null)}><X size={16} /></button>
            </div>
            <div className="share-modal__body">
              <table className="props-table">
                <tbody>
                  <tr><td>Name</td><td>{propsModal.name}</td></tr>
                  <tr><td>Path</td><td>{propsModal.path}</td></tr>
                  <tr><td>Type</td><td>{propsModal.isdir ? 'Folder' : (propsModal.additional?.type || 'File')}</td></tr>
                  <tr><td>Size</td><td>{formatFileSize(propsModal.additional?.size || 0)}</td></tr>
                  <tr><td>Owner</td><td>{propsModal.additional?.owner?.user || '—'}</td></tr>
                  {propsModal.additional?.time?.mtime && (
                    <tr><td>Modified</td><td>{new Date(propsModal.additional.time.mtime * 1000).toLocaleString()}</td></tr>
                  )}
                  {propsModal.additional?.time?.crtime && (
                    <tr><td>Created</td><td>{new Date(propsModal.additional.time.crtime * 1000).toLocaleString()}</td></tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}
      {DialogComponent}
    </div>
  );
};

// ── Helpers ─────────────────────────────────

function FileIcon({ name }: { name: string }) {
  const ext = name.split('.').pop()?.toLowerCase() || '';
  const imageExts = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg', 'ico'];
  const videoExts = ['mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', 'webm'];
  const audioExts = ['mp3', 'wav', 'flac', 'aac', 'ogg', 'wma', 'm4a'];
  const archiveExts = ['zip', 'rar', '7z', 'tar', 'gz', 'bz2', 'xz'];
  const codeExts = ['js', 'ts', 'py', 'rs', 'go', 'java', 'cpp', 'c', 'h', 'html', 'css', 'json', 'xml', 'yaml', 'yml', 'toml', 'sh', 'bat'];

  if (imageExts.includes(ext)) return <FileImage size={18} className="filestation__icon-image" />;
  if (videoExts.includes(ext)) return <FileVideo size={18} className="filestation__icon-video" />;
  if (audioExts.includes(ext)) return <FileAudio size={18} className="filestation__icon-audio" />;
  if (archiveExts.includes(ext)) return <FileArchive size={18} className="filestation__icon-archive" />;
  if (codeExts.includes(ext)) return <FileCode size={18} className="filestation__icon-code" />;
  return <FileText size={18} className="filestation__icon-file" />;
}

function formatFileSize(bytes: number): string {
  if (bytes === 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  const i = Math.floor(Math.log(bytes) / Math.log(1024));
  return `${(bytes / Math.pow(1024, i)).toFixed(i > 0 ? 1 : 0)} ${units[i]}`;
}

function formatDate(unixTime: number): string {
  const d = new Date(unixTime * 1000);
  const now = new Date();
  const isToday = d.toDateString() === now.toDateString();
  if (isToday) return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  return d.toLocaleDateString([], { year: 'numeric', month: 'short', day: 'numeric' });
}

export default FileStation;
