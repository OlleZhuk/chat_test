import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../view_model/widgets/divider.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  GalleryScreenState createState() => GalleryScreenState();
}

class GalleryScreenState extends State<GalleryScreen> {
  List<AssetEntity> _images = [];
  int _selectedIndex = 0; // Индекс активной кнопки

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildContent(),
      bottomNavigationBar: BottomAppBar(
        height: 120,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 5,
          itemBuilder: (context, index) {
            //> Список данных для кнопок
            final List<Map<String, dynamic>> navItems = [
              {'icon': Icons.image, 'label': 'Галерея', 'color': Colors.blue},
              {'icon': Icons.videocam, 'label': 'Видео', 'color': Colors.red},
              {
                'icon': Icons.audiotrack,
                'label': 'Аудио',
                'color': Colors.green
              },
              {
                'icon': Icons.description,
                'label': 'Документ',
                'color': Colors.orange
              },
              {
                'icon': Icons.insert_drive_file,
                'label': 'Файл',
                'color': Colors.purple
              },
            ];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: Column(
                children: [
                  _buildNavButton(index, navItems[index]['icon'],
                      navItems[index]['label'], navItems[index]['color']),
                  Text(navItems[index]['label'],
                      style: const TextStyle(fontSize: 10)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  //* Метод загрузки изображений галереи
  Future<void> _loadImages() async {
    //> Запрос разрешения
    final PermissionState permission =
        await PhotoManager.requestPermissionExtend();
    if (permission.isAuth) {
      //> Получаем альбомы
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
      );

      if (albums.isNotEmpty) {
        //> Получаем все изображения из первого альбома
        // start: 0, end: 100 --> ограничения кол-ва
        final List<AssetEntity> images =
            await albums.first.getAssetListRange(start: 0, end: 100);

        setState(() {
          _images = images;
        });
      }
    } else {
      //> Если разрешение не предоставлено
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Разрешение на доступ к галерее отклонено пользователем')),
        );
      }
    }
  }

  //* Виджет для кнопки навбара
  Widget _buildNavButton(
      int index, IconData icon, String tooltip, Color color) {
    return IconButton(
      onPressed: () {
        setState(() {
          _selectedIndex = index; // Обновляем активную кнопку
        });
      },
      icon: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: _selectedIndex == index
              ? Border.all(
                  color: color, width: 2) // Обводка для активной кнопки
              : null,
        ),
        child: CircleAvatar(
          minRadius: 24,
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
      ),
      tooltip: tooltip,
    );
  }

  //* Контент в зависимости от выбранной кнопки
  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildGalleryContent();
      case 1:
        return _buildVideoContent();
      case 2:
        return _buildAudioContent();
      case 3:
        return _buildDocumentContent();
      case 4:
        return _buildFileContent();
      default:
        return const Center(child: Text('Выберите раздел'));
    }
  }

  //* Билдеры контента
  Widget _buildGalleryContent() {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              children: [
                BackButton(onPressed: () => Navigator.pop(context)),
                const Text('Галерея', style: TextStyle(fontSize: 18)),
                Expanded(child: dividerBuilder(Colors.blue)),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 3 изображения в ряду
                crossAxisSpacing: 3, // Отступы между изображениями
                mainAxisSpacing: 3,
                childAspectRatio: 1, // Формат 1x1
              ),
              itemCount: _images.length,
              itemBuilder: (context, index) {
                final asset = _images[index];

                return FutureBuilder<Uint8List?>(
                  future: asset.thumbnailData,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      return Image.memory(
                        snapshot.data!,
                        fit: BoxFit.cover,
                      );
                    } else {
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoContent() {
    return const Center(child: Text('Видео'));
  }

  Widget _buildAudioContent() {
    return const Center(child: Text('Аудио'));
  }

  Widget _buildDocumentContent() {
    return const Center(child: Text('Документ'));
  }

  Widget _buildFileContent() {
    return const Center(child: Text('Файл'));
  }
}
