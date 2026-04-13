import React, { useState, useCallback, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { AlertTriangle, Trash2, Info, CheckCircle } from 'lucide-react';
import './ConfirmDialog.css';

// ── Types ──

export type DialogVariant = 'danger' | 'warning' | 'info' | 'success';

export interface ConfirmDialogProps {
  open: boolean;
  title: string;
  message: string;
  variant?: DialogVariant;
  confirmText?: string;
  cancelText?: string;
  showCancel?: boolean;   // false = alert mode (OK only)
  onConfirm: () => void;
  onCancel: () => void;
}

const variantIcons: Record<DialogVariant, React.ElementType> = {
  danger: Trash2,
  warning: AlertTriangle,
  info: Info,
  success: CheckCircle,
};

/**
 * ConfirmDialog — A premium replacement for native confirm()/alert().
 * Renders via portal at document.body so it overlays everything.
 */
const ConfirmDialog: React.FC<ConfirmDialogProps> = ({
  open,
  title,
  message,
  variant = 'info',
  confirmText,
  cancelText = 'Cancel',
  showCancel = true,
  onConfirm,
  onCancel,
}) => {
  const [closing, setClosing] = useState(false);
  const Icon = variantIcons[variant];

  const defaultConfirmText = confirmText || (variant === 'danger' ? 'Delete' : 'OK');

  const handleClose = useCallback((confirmed: boolean) => {
    setClosing(true);
    setTimeout(() => {
      setClosing(false);
      if (confirmed) onConfirm();
      else onCancel();
    }, 200); // match animation duration
  }, [onConfirm, onCancel]);

  // ESC key to cancel
  useEffect(() => {
    if (!open) return;
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'Escape') handleClose(false);
      if (e.key === 'Enter') handleClose(true);
    };
    window.addEventListener('keydown', handler);
    return () => window.removeEventListener('keydown', handler);
  }, [open, handleClose]);

  if (!open) return null;

  return createPortal(
    <div
      className={`confirm-overlay ${closing ? 'confirm-overlay--closing' : ''}`}
      onClick={() => handleClose(false)}
    >
      <div className="confirm-dialog" onClick={e => e.stopPropagation()}>
        <div className={`confirm-dialog__icon confirm-dialog__icon--${variant}`}>
          <Icon size={22} />
        </div>
        <h3 className="confirm-dialog__title">{title}</h3>
        <p className="confirm-dialog__message">{message}</p>
        <div className="confirm-dialog__actions">
          {showCancel && (
            <button
              className="confirm-dialog__btn"
              onClick={() => handleClose(false)}
            >
              {cancelText}
            </button>
          )}
          <button
            className={`confirm-dialog__btn confirm-dialog__btn--${variant}`}
            onClick={() => handleClose(true)}
            autoFocus
          >
            {defaultConfirmText}
          </button>
        </div>
      </div>
    </div>,
    document.body
  );
};

export default ConfirmDialog;

// ── Hook: useConfirmDialog ──
// Convenient hook to use ConfirmDialog imperatively

interface DialogConfig {
  title: string;
  message: string;
  variant?: DialogVariant;
  confirmText?: string;
  cancelText?: string;
  showCancel?: boolean;
}

export function useConfirmDialog() {
  const [dialogState, setDialogState] = useState<{
    open: boolean;
    config: DialogConfig;
    resolve: ((confirmed: boolean) => void) | null;
  }>({
    open: false,
    config: { title: '', message: '' },
    resolve: null,
  });

  const showDialog = useCallback((config: DialogConfig): Promise<boolean> => {
    return new Promise(resolve => {
      setDialogState({ open: true, config, resolve });
    });
  }, []);

  const handleConfirm = useCallback(() => {
    dialogState.resolve?.(true);
    setDialogState(s => ({ ...s, open: false, resolve: null }));
  }, [dialogState.resolve]);

  const handleCancel = useCallback(() => {
    dialogState.resolve?.(false);
    setDialogState(s => ({ ...s, open: false, resolve: null }));
  }, [dialogState.resolve]);

  const DialogComponent = (
    <ConfirmDialog
      open={dialogState.open}
      title={dialogState.config.title}
      message={dialogState.config.message}
      variant={dialogState.config.variant}
      confirmText={dialogState.config.confirmText}
      cancelText={dialogState.config.cancelText}
      showCancel={dialogState.config.showCancel}
      onConfirm={handleConfirm}
      onCancel={handleCancel}
    />
  );

  return { showDialog, DialogComponent };
}
