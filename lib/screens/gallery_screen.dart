import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/gallery_provider.dart';
import '../models/image_data.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GalleryProvider>().loadGallery();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GalleryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
        actions: [
          IconButton(
            icon: Icon(provider.isGrid ? Icons.view_list : Icons.grid_view),
            onPressed: () => provider.toggleViewMode(),
            tooltip: provider.isGrid ? 'List view' : 'Grid view',
          ),
          PopupMenuButton<String>(
            onSelected: provider.setSortBy,
            itemBuilder: (_) => [
              PopupMenuItem(value: 'date', child: Text('Sort by Date', style: TextStyle(
                fontWeight: provider.sortBy == 'date' ? FontWeight.bold : FontWeight.normal,
              ))),
              PopupMenuItem(value: 'name', child: Text('Sort by Name', style: TextStyle(
                fontWeight: provider.sortBy == 'name' ? FontWeight.bold : FontWeight.normal,
              ))),
              PopupMenuItem(value: 'size', child: Text('Sort by Size', style: TextStyle(
                fontWeight: provider.sortBy == 'size' ? FontWeight.bold : FontWeight.normal,
              ))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(provider),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.images.isEmpty
                    ? _buildEmptyState()
                    : provider.isGrid
                        ? _buildGridView(provider)
                        : _buildListView(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(GalleryProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search images...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    provider.setSearchQuery('');
                  },
                )
              : null,
        ),
        onChanged: provider.setSearchQuery,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(Icons.photo_library, size: 80, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Text('No Images Yet', style: AppStyles.heading2),
          const SizedBox(height: 12),
          Text(
            'Edited images will appear here',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(GalleryProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.loadGallery(),
      color: AppColors.primary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          itemCount: provider.images.length,
          itemBuilder: (_, index) {
            final image = provider.images[index];
            return _GalleryGridItem(
              image: image,
              onTap: () => _showImagePreview(context, image),
              onDelete: () => provider.deleteImage(image.id),
              onShare: () => _shareImage(image),
            );
          },
        ),
      ),
    );
  }

  Widget _buildListView(GalleryProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.loadGallery(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: provider.images.length,
        itemBuilder: (_, index) {
          final image = provider.images[index];
          return _GalleryListItem(
            image: image,
            onTap: () => _showImagePreview(context, image),
            onDelete: () => provider.deleteImage(image.id),
            onShare: () => _shareImage(image),
          );
        },
      ),
    );
  }

  void _showImagePreview(BuildContext context, ImageData image) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text(image.name, style: const TextStyle(fontSize: 14)),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _shareImage(image),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  context.read<GalleryProvider>().deleteImage(image.id);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          body: PhotoView(
            imageProvider: FileImage(File(image.path)),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
          bottomNavigationBar: Container(
            color: Colors.black87,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(image.sizeFormatted, style: const TextStyle(color: Colors.grey)),
                Text(
                  '${image.width} × ${image.height}',
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  Helpers.formatDate(image.createdAt),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _shareImage(ImageData image) async {
    Helpers.showSnackBar(context, 'Share feature coming soon');
  }
}

class _GalleryGridItem extends StatelessWidget {
  final ImageData image;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  const _GalleryGridItem({
    required this.image,
    required this.onTap,
    required this.onDelete,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showContextMenu(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: image.aspectRatio,
              child: Image.file(
                File(image.path),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.card,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    image.name.length > 20
                        ? '${image.name.substring(0, 20)}...'
                        : image.name,
                    style: AppStyles.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    image.sizeFormatted,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('View'),
                onTap: () { Navigator.pop(context); onTap(); },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share'),
                onTap: () { Navigator.pop(context); onShare(); },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Details'),
                onTap: () { Navigator.pop(context); },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: const Text('Delete Image'),
                      content: const Text('Are you sure you want to delete this image?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () { Navigator.pop(context); onDelete(); },
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GalleryListItem extends StatelessWidget {
  final ImageData image;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  const _GalleryListItem({
    required this.image,
    required this.onTap,
    required this.onDelete,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(image.path),
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 72,
                  height: 72,
                  color: AppColors.cardLight,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(image.name, style: AppStyles.label, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    '${image.sizeFormatted} • ${image.width}×${image.height}',
                    style: AppStyles.caption,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Helpers.formatDate(image.createdAt),
                    style: AppStyles.caption,
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'delete') onDelete();
                if (v == 'share') onShare();
                if (v == 'view') onTap();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'view', child: ListTile(
                  leading: Icon(Icons.visibility),
                  title: Text('View'),
                  dense: true,
                )),
                const PopupMenuItem(value: 'share', child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Share'),
                  dense: true,
                )),
                const PopupMenuItem(value: 'delete', child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete', style: TextStyle(color: Colors.red)),
                  dense: true,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
