import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../model/navbar_buttons.dart';
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
    _loadAssets(RequestType.image);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildContent(),
      //
      bottomNavigationBar: BottomAppBar(
        height: 120,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 5,
          itemBuilder: (context, index) {
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

  /// МЕТОДЫ ЗАГРУЗКИ, ОТОБРАЖЕНИЯ И ПЕРЕДАЧИ ФАЙЛОВ

  //* Загрузка файлов
  Future<void> _loadAssets(type) async {
    if (type == RequestType.image || type == RequestType.video) {
      // Используем photo_manager для изображений и видео
      final PermissionState permission =
          await PhotoManager.requestPermissionExtend();
      if (permission.isAuth) {
        final List<AssetPathEntity> albums =
            await PhotoManager.getAssetPathList(type: type);

        if (albums.isNotEmpty) {
          final List<AssetEntity> assets =
              await albums.first.getAssetListRange(start: 0, end: 100);
          setState(() => _images = assets);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Разрешение на доступ к галерее отклонено пользователем'),
            ),
          );
        }
      }
    } else {
      FileType fileType;
      List<String>? allowedExtensions;
      // Определяем тип файлов для file_picker
      switch (_selectedIndex) {
        case 2:
          fileType = FileType.audio; // Только аудио-файлы
          break;
        case 3:
          fileType = FileType.custom; // Пользовательский тип (документы)
          allowedExtensions = ['pdf', 'docx', 'xlsx', 'txt'];
          break;
        case 4:
          fileType = FileType.any; // Любые файлы
          break;
        default:
          fileType = FileType.any; // По умолчанию любые файлы
      }
      // Используем file_picker для документов и других файлов
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: fileType,
        allowedExtensions: allowedExtensions,
        // Выбор только одного файла
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final File file = File(result.files.single.path!);
        // Возвращаем выбранный файл
        if (mounted) Navigator.pop(context, file);
      }
    }
  }

  //* Контент в зависимости от кнопки
  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildAssetContent('Галерея', Colors.blue, _images);
      case 1:
        return _buildAssetContent('Видео', Colors.red, _images);
      default:
        return const Center(child: Text('Выберите раздел'));
    }
  }

  //* Виджет кнопки навбара
  Widget _buildNavButton(
      int index, IconData icon, String tooltip, Color color) {
    return IconButton(
      onPressed: () {
        setState(() {
          //> Обновление активной кнопки
          _selectedIndex = index;
          //> Вызов загрузки файлов
          switch (index) {
            case 0:
              _loadAssets(RequestType.image);
              break;
            case 1:
              _loadAssets(RequestType.video);
              break;
            case 2:
              _loadAssets(RequestType.audio); // Для других файлов
              break;
            case 3:
              _loadAssets(RequestType.all); // Для других файлов
              break;
            case 4:
              _loadAssets(RequestType.all); // Для других файлов
              break;
          }
        });
      },
      icon: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: _selectedIndex == index
              //> Обводка для активной кнопки
              ? Border.all(color: color, width: 2)
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

  //* Билдер сетки отображения
  Widget _buildAssetContent(
    String title,
    Color color,
    List<dynamic> assets,
  ) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              children: [
                BackButton(onPressed: () => Navigator.pop(context)),
                Text(title, style: const TextStyle(fontSize: 18)),
                Expanded(child: dividerBuilder(color)),
              ],
            ),
          ),
          Expanded(
              child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 3,
              mainAxisSpacing: 3,
              childAspectRatio: 1,
            ),
            itemCount: assets.length,
            itemBuilder: (context, index) {
              final asset = assets[index];
              return FutureBuilder<Uint8List?>(
                future: asset.thumbnailData,
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return GestureDetector(
                      onTap: () => Navigator.pop(context, asset),
                      child: Image.memory(
                        snapshot.data!,
                        fit: BoxFit.cover,
                      ),
                    );
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              );
            },
          )),
        ],
      ),
    );
  }
}
