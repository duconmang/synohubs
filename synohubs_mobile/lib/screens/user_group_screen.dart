import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../services/session_manager.dart';
import '../l10n/app_localizations.dart';

class UserGroupScreen extends StatefulWidget {
  const UserGroupScreen({super.key});

  @override
  State<UserGroupScreen> createState() => _UserGroupScreenState();
}

class _UserGroupScreenState extends State<UserGroupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _groups = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    setState(() => _loading = true);
    final api = SessionManager.instance.api;
    if (api == null) return;

    try {
      final results = await Future.wait([api.listUsers(), api.listGroups()]);

      if (results[0]['success'] == true) {
        final data = results[0]['data'] as Map<String, dynamic>? ?? {};
        _users = List<Map<String, dynamic>>.from(data['users'] as List? ?? []);
      }

      if (results[1]['success'] == true) {
        final data = results[1]['data'] as Map<String, dynamic>? ?? {};
        _groups = List<Map<String, dynamic>>.from(
          data['groups'] as List? ?? [],
        );
      }
    } catch (_) {}

    _loading = false;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.people,
                color: AppColors.primaryContainer,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              l.userAndGroup,
              style: GoogleFonts.manrope(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryContainer,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.primaryContainer,
          indicatorWeight: 2.5,
          labelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(text: l.users),
            Tab(text: l.groups),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : TabBarView(
              controller: _tabController,
              children: [_buildUsersTab(), _buildGroupsTab()],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryContainer,
        onPressed: _onFabTap,
        child: const Icon(Icons.add, color: AppColors.onPrimary),
      ),
    );
  }

  void _onFabTap() {
    if (_tabController.index == 0) {
      _showCreateUserDialog();
    } else {
      _showCreateGroupDialog();
    }
  }

  /// Detect if a user is disabled/expired.
  /// Handles multiple DSM response formats:
  ///  - expired: "true" (string)
  ///  - expired: true (bool)
  ///  - expired: {"expired": "true"} (nested object)
  ///  - enabled: false / "false" (some DSM versions)
  bool _isUserDisabled(Map<String, dynamic> user) {
    final exp = user['expired'];
    // Nested object: {"expired": "true"}
    if (exp is Map) {
      final inner = exp['expired'];
      if (inner == true || inner == 'true' || inner == 'True') return true;
    }
    // Direct string or bool
    if (exp == true || exp == 'true' || exp == 'True') return true;
    // Some DSM versions use 'enabled' field
    final enabled = user['enabled'];
    if (enabled == false || enabled == 'false' || enabled == 'False') {
      return true;
    }
    return false;
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAB 1: Users
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildUsersTab() {
    final l = AppLocalizations.of(context)!;
    if (_users.isEmpty) {
      return _emptyState(l.noUsers, Icons.people_outline);
    }

    return Column(
      children: [
        // Counter
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Text(
                l.allUsers,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  l.nUsers(_users.length),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _fetchAll,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _users.length,
              itemBuilder: (ctx, i) => _buildUserCard(_users[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final l = AppLocalizations.of(context)!;
    final name = user['name'] as String? ?? '';
    final desc = user['description'] as String? ?? '';
    final email = user['email'] as String? ?? '';
    final expired = _isUserDisabled(user);
    final isAdmin = name == 'admin' || (user['is_manager'] == true);

    final statusColor = expired ? AppColors.error : AppColors.secondary;
    final statusText = expired ? l.disabled : l.active;

    // Generate avatar color from name
    final avatarColor = _avatarColor(name);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        borderRadius: 16,
        padding: const EdgeInsets.all(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showUserDetail(user),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: avatarColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: avatarColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.tertiary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              l.admin,
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: AppColors.tertiary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (desc.isNotEmpty)
                      Text(
                        desc,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.primaryContainer,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Status badge
              Column(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statusText,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAB 2: Groups
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildGroupsTab() {
    final l = AppLocalizations.of(context)!;
    if (_groups.isEmpty) {
      return _emptyState(l.noGroups, Icons.group_work_outlined);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Text(
                l.allGroups,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  l.nGroups(_groups.length),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _fetchAll,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _groups.length,
              itemBuilder: (ctx, i) => _buildGroupCard(_groups[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    final l = AppLocalizations.of(context)!;
    final name = group['name'] as String? ?? '';
    final desc = group['description'] as String? ?? '';
    final members = group['members'] as List? ?? [];
    final isSystem =
        name == 'administrators' || name == 'users' || name == 'http';
    final avatarColor = _avatarColor(name);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        borderRadius: 16,
        padding: const EdgeInsets.all(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showGroupDetail(group),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: avatarColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.group, color: avatarColor, size: 22),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSystem) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.onSurfaceVariant.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              l.systemGroup,
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (desc.isNotEmpty)
                      Text(
                        desc,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Member count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person,
                      size: 12,
                      color: AppColors.primaryContainer,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${members.length}',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // User Detail Bottom Sheet
  // ═══════════════════════════════════════════════════════════════════
  void _showUserDetail(Map<String, dynamic> user) {
    final l = AppLocalizations.of(context)!;
    final name = user['name'] as String? ?? '';
    final desc = user['description'] as String? ?? '';
    final email = user['email'] as String? ?? '';
    final expired = _isUserDisabled(user);
    final isAdmin = name == 'admin' || (user['is_manager'] == true);
    final avatarColor = _avatarColor(name);

    // Find which groups this user belongs to
    final userGroups = <String>[];
    for (final g in _groups) {
      final members = g['members'] as List? ?? [];
      for (final m in members) {
        final memberName = m is Map
            ? (m['name'] as String? ?? '')
            : m.toString();
        if (memberName == name) {
          userGroups.add(g['name'] as String? ?? '');
          break;
        }
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Avatar + Name
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: avatarColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: GoogleFonts.manrope(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: avatarColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                if (isAdmin) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.tertiary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      l.admin,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tertiary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: (expired ? AppColors.error : AppColors.secondary)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                expired ? l.disabled : l.active,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: expired ? AppColors.error : AppColors.secondary,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Detail rows
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  if (desc.isNotEmpty)
                    _detailRow(Icons.info_outline, l.description, desc),
                  if (email.isNotEmpty)
                    _detailRow(Icons.email_outlined, l.email, email),
                  if (userGroups.isNotEmpty)
                    _detailRow(Icons.group, l.groups, userGroups.join(', ')),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _sheetActionButton(
                      Icons.edit,
                      l.edit,
                      AppColors.primaryContainer,
                      () {
                        Navigator.pop(ctx);
                        _showEditUserDialog(user);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _sheetActionButton(
                      expired ? Icons.check_circle : Icons.block,
                      expired ? l.enable : l.disable,
                      expired ? AppColors.secondary : AppColors.tertiary,
                      () {
                        Navigator.pop(ctx);
                        _toggleUserEnabled(name, expired);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _sheetActionButton(
                      Icons.password,
                      l.password,
                      AppColors.primary,
                      () {
                        Navigator.pop(ctx);
                        _showChangePasswordDialog(name);
                      },
                    ),
                  ),
                  if (!isAdmin && name != 'admin') ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _sheetActionButton(
                        Icons.delete_outline,
                        l.delete,
                        AppColors.error,
                        () {
                          Navigator.pop(ctx);
                          _confirmDeleteUser(name);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Group Detail Bottom Sheet
  // ═══════════════════════════════════════════════════════════════════
  void _showGroupDetail(Map<String, dynamic> group) {
    final l = AppLocalizations.of(context)!;
    final name = group['name'] as String? ?? '';
    final desc = group['description'] as String? ?? '';
    final members = group['members'] as List? ?? [];
    final isSystem =
        name == 'administrators' || name == 'users' || name == 'http';
    final avatarColor = _avatarColor(name);

    // Parse member names
    final memberNames = members
        .map((m) {
          if (m is Map) return m['name'] as String? ?? '';
          return m.toString();
        })
        .where((n) => n.isNotEmpty)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Group icon + Name
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: avatarColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.group, color: avatarColor, size: 30),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
                  if (isSystem) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.onSurfaceVariant.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        l.systemGroup,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Members list
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.people,
                          size: 14,
                          color: AppColors.primaryContainer,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l.membersCount(memberNames.length),
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryContainer,
                          ),
                        ),
                        const Spacer(),
                        if (!isSystem)
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              _showManageMembersDialog(name, memberNames);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.edit,
                                    size: 12,
                                    color: AppColors.primaryContainer,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    l.manage,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (memberNames.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          l.noMembers,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      )
                    else
                      ...memberNames.map((m) => _memberChip(m)),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Actions
              if (!isSystem)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: _sheetActionButton(
                          Icons.edit,
                          l.edit,
                          AppColors.primaryContainer,
                          () {
                            Navigator.pop(ctx);
                            _showEditGroupDialog(group);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _sheetActionButton(
                          Icons.delete_outline,
                          l.delete,
                          AppColors.error,
                          () {
                            Navigator.pop(ctx);
                            _confirmDeleteGroup(name);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _memberChip(String name) {
    final color = _avatarColor(name);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GlassCard(
        borderRadius: 10,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Dialogs: Create User
  // ═══════════════════════════════════════════════════════════════════
  void _showCreateUserDialog() {
    final l = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    _showFormDialog(
      title: l.createUser,
      fields: [
        _dialogField(l.username, nameCtrl, Icons.person),
        _dialogField(l.password, passCtrl, Icons.lock, obscure: true),
        _dialogField(l.email, emailCtrl, Icons.email),
        _dialogField(l.description, descCtrl, Icons.info_outline),
      ],
      onConfirm: () async {
        if (nameCtrl.text.trim().isEmpty || passCtrl.text.trim().isEmpty) {
          _showSnack(l.usernameAndPasswordRequired);
          return;
        }
        final api = SessionManager.instance.api;
        if (api == null) return;
        final resp = await api.createUser(
          name: nameCtrl.text.trim(),
          password: passCtrl.text,
          email: emailCtrl.text.trim(),
          description: descCtrl.text.trim(),
        );
        if (resp['success'] == true) {
          _showSnack(l.userCreatedSuccessfully);
          _fetchAll();
        } else {
          _showApiError(resp);
        }
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Dialogs: Edit User
  // ═══════════════════════════════════════════════════════════════════
  void _showEditUserDialog(Map<String, dynamic> user) {
    final l = AppLocalizations.of(context)!;
    final name = user['name'] as String? ?? '';
    final emailCtrl = TextEditingController(
      text: user['email'] as String? ?? '',
    );
    final descCtrl = TextEditingController(
      text: user['description'] as String? ?? '',
    );

    _showFormDialog(
      title: l.editName(name),
      fields: [
        _dialogField(l.email, emailCtrl, Icons.email),
        _dialogField(l.description, descCtrl, Icons.info_outline),
      ],
      onConfirm: () async {
        final api = SessionManager.instance.api;
        if (api == null) return;
        final resp = await api.editUser(
          name: name,
          email: emailCtrl.text.trim(),
          description: descCtrl.text.trim(),
        );
        if (resp['success'] == true) {
          _showSnack(l.userUpdated);
          _fetchAll();
        } else {
          _showApiError(resp);
        }
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Dialogs: Change Password
  // ═══════════════════════════════════════════════════════════════════
  void _showChangePasswordDialog(String userName) {
    final l = AppLocalizations.of(context)!;
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    _showFormDialog(
      title: l.changePasswordTitle(userName),
      fields: [
        _dialogField(l.newPassword, passCtrl, Icons.lock, obscure: true),
        _dialogField(
          l.confirmPassword,
          confirmCtrl,
          Icons.lock_outline,
          obscure: true,
        ),
      ],
      onConfirm: () async {
        if (passCtrl.text.isEmpty) {
          _showSnack(l.passwordCannotBeEmpty);
          return;
        }
        if (passCtrl.text != confirmCtrl.text) {
          _showSnack(l.passwordsDoNotMatch);
          return;
        }
        final api = SessionManager.instance.api;
        if (api == null) return;
        final resp = await api.editUser(
          name: userName,
          password: passCtrl.text,
        );
        if (resp['success'] == true) {
          _showSnack(l.passwordChanged);
        } else {
          _showApiError(resp);
        }
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Toggle Enable/Disable User
  // ═══════════════════════════════════════════════════════════════════
  Future<void> _toggleUserEnabled(String name, bool currentlyExpired) async {
    final l = AppLocalizations.of(context)!;
    final api = SessionManager.instance.api;
    if (api == null) return;
    final resp = await api.setUserEnabled(
      name: name,
      enabled: currentlyExpired, // reverse
    );
    if (resp['success'] == true) {
      _showSnack(currentlyExpired ? l.userEnabled(name) : l.userDisabled(name));
      _fetchAll();
    } else {
      _showApiError(resp);
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Delete User
  // ═══════════════════════════════════════════════════════════════════
  void _confirmDeleteUser(String name) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l.deleteUserTitle,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        content: Text(
          l.deleteUserMessage(name),
          style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l.cancel,
              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final api = SessionManager.instance.api;
              if (api == null) return;
              final resp = await api.deleteUser(name);
              if (resp['success'] == true) {
                _showSnack(l.userDeleted(name));
                _fetchAll();
              } else {
                _showApiError(resp);
              }
            },
            child: Text(
              l.delete,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Dialogs: Create Group
  // ═══════════════════════════════════════════════════════════════════
  void _showCreateGroupDialog() {
    final l = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    _showFormDialog(
      title: l.createGroup,
      fields: [
        _dialogField(l.groupName, nameCtrl, Icons.group),
        _dialogField(l.description, descCtrl, Icons.info_outline),
      ],
      onConfirm: () async {
        if (nameCtrl.text.trim().isEmpty) {
          _showSnack(l.groupNameRequired);
          return;
        }
        final api = SessionManager.instance.api;
        if (api == null) return;
        final resp = await api.createGroup(
          name: nameCtrl.text.trim(),
          description: descCtrl.text.trim(),
        );
        if (resp['success'] == true) {
          _showSnack(l.groupCreated);
          _fetchAll();
        } else {
          _showApiError(resp);
        }
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Edit Group
  // ═══════════════════════════════════════════════════════════════════
  void _showEditGroupDialog(Map<String, dynamic> group) {
    final l = AppLocalizations.of(context)!;
    final name = group['name'] as String? ?? '';
    final descCtrl = TextEditingController(
      text: group['description'] as String? ?? '',
    );

    _showFormDialog(
      title: l.editName(name),
      fields: [_dialogField(l.description, descCtrl, Icons.info_outline)],
      onConfirm: () async {
        final api = SessionManager.instance.api;
        if (api == null) return;
        final resp = await api.editGroup(
          name: name,
          description: descCtrl.text.trim(),
        );
        if (resp['success'] == true) {
          _showSnack(l.groupUpdated);
          _fetchAll();
        } else {
          _showApiError(resp);
        }
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Delete Group
  // ═══════════════════════════════════════════════════════════════════
  void _confirmDeleteGroup(String name) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l.deleteGroupTitle,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        content: Text(
          l.deleteGroupMessage(name),
          style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l.cancel,
              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final api = SessionManager.instance.api;
              if (api == null) return;
              final resp = await api.deleteGroup(name);
              if (resp['success'] == true) {
                _showSnack(l.groupDeleted(name));
                _fetchAll();
              } else {
                _showApiError(resp);
              }
            },
            child: Text(
              l.delete,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Manage Members (add/remove users from group)
  // ═══════════════════════════════════════════════════════════════════
  void _showManageMembersDialog(String groupName, List<String> currentMembers) {
    final l = AppLocalizations.of(context)!;
    final selected = Set<String>.from(currentMembers);
    final allUserNames = _users
        .map((u) => u['name'] as String? ?? '')
        .where((n) => n.isNotEmpty)
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          return AlertDialog(
            backgroundColor: AppColors.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              l.membersOfGroup(groupName),
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: allUserNames.length,
                itemBuilder: (_, i) {
                  final userName = allUserNames[i];
                  final isMember = selected.contains(userName);
                  return CheckboxListTile(
                    dense: true,
                    value: isMember,
                    activeColor: AppColors.primaryContainer,
                    title: Text(
                      userName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    onChanged: (val) {
                      setDlgState(() {
                        if (val == true) {
                          selected.add(userName);
                        } else {
                          selected.remove(userName);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  l.cancel,
                  style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final api = SessionManager.instance.api;
                  if (api == null) return;

                  // Compute diff
                  final toAdd = selected
                      .where((u) => !currentMembers.contains(u))
                      .toList();
                  final toRemove = currentMembers
                      .where((u) => !selected.contains(u))
                      .toList();

                  if (toAdd.isNotEmpty) {
                    await api.addGroupMembers(group: groupName, members: toAdd);
                  }
                  if (toRemove.isNotEmpty) {
                    await api.removeGroupMembers(
                      group: groupName,
                      members: toRemove,
                    );
                  }
                  _showSnack(l.membersUpdated);
                  _fetchAll();
                },
                child: Text(
                  l.save,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryContainer,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Shared helpers
  // ═══════════════════════════════════════════════════════════════════
  Widget _emptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 48,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        borderRadius: 12,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showFormDialog({
    required String title,
    required List<Widget> fields,
    required Future<void> Function() onConfirm,
  }) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: fields),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l.cancel,
              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await onConfirm();
            },
            child: Text(
              l.confirm,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.onSurfaceVariant,
          ),
          prefixIcon: Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryContainer),
          ),
          filled: true,
          fillColor: AppColors.surfaceContainerLowest.withValues(alpha: 0.5),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(fontSize: 12)),
        backgroundColor: AppColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showApiError(Map<String, dynamic> resp) {
    final l = AppLocalizations.of(context)!;
    final code = resp['error']?['code'];
    String msg;
    switch (code) {
      case 105:
        msg = l.insufficientPermission;
        break;
      case 400:
        msg = l.invalidParameter;
        break;
      case 401:
        msg = l.accountIsDisabled;
        break;
      case 402:
        msg = l.permissionDenied;
        break;
      case 404:
        msg = l.userGroupNotFound;
        break;
      case 409:
        msg = l.nameAlreadyExists;
        break;
      default:
        msg = l.operationFailedCode(code ?? 0);
    }
    _showSnack(msg);
  }

  Color _avatarColor(String name) {
    if (name.isEmpty) return AppColors.primary;
    final colors = [
      AppColors.primaryContainer,
      AppColors.secondary,
      AppColors.tertiary,
      AppColors.primary,
      const Color(0xFF9C27B0),
      const Color(0xFFFF5722),
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
    ];
    return colors[name.codeUnitAt(0) % colors.length];
  }
}
