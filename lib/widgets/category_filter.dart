import 'package:flutter/material.dart';
import 'home_state_manager.dart';

class CategoryFilterWidget extends StatelessWidget {
  final HomeStateManager stateManager;
  final VoidCallback onCategoryChanged;

  const CategoryFilterWidget({
    Key? key,
    required this.stateManager,
    required this.onCategoryChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: stateManager.isCategoryFilterActive ? Colors.blue : Colors.grey[300]!,
          width: stateManager.isCategoryFilterActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => stateManager.showCategoryDialog(context, onCategoryChanged),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.category,
                color: stateManager.isCategoryFilterActive ? Colors.blue : Colors.grey[600],
                size: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Категории',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      stateManager.displayCategoriesText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: stateManager.isCategoryFilterActive ? Colors.blue : Colors.black87,
                      ),
                    ),
                    if (stateManager.isCategoryFilterActive && stateManager.selectedCategories.length > 1)
                      SizedBox(height: 4),
                    if (stateManager.isCategoryFilterActive && stateManager.selectedCategories.length > 1)
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: stateManager.selectedCategories.take(3).map((category) {
                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              category.length > 10 ? '${category.substring(0, 10)}...' : category,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              // Бейдж с количеством выбранных категорий
              if (stateManager.isCategoryFilterActive)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${stateManager.selectedCategories.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              SizedBox(width: 8),
              Icon(
                Icons.arrow_drop_down,
                color: stateManager.isCategoryFilterActive ? Colors.blue : Colors.grey[600],
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}