import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/library_controller.dart';
import 'library_tab_enum.dart';


class LibraryTabSelector extends StatelessWidget {
  const LibraryTabSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryController>(
      builder: (context, controller, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: LibraryTab.values.map((tab) {
              final isSelected = controller.selectedTab == tab;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: () => controller.selectTab(tab),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.3)),
                      borderRadius: BorderRadius.circular(30),
                      color: isSelected 
                        ? const Color.fromRGBO(251, 176, 60, 0.8) 
                        : Colors.transparent,
                    ),
                    child: Text(
                      tab.label,
                      style: TextStyle(
                        color: isSelected 
                          ? Colors.white 
                          : Colors.white,
                        fontSize: 16,
                        fontWeight: isSelected 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
} 