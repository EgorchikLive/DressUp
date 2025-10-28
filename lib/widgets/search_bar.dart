import 'package:flutter/material.dart';
import 'home_state_manager.dart';

class SearchBarWidget extends StatelessWidget {
  final HomeStateManager stateManager;

  const SearchBarWidget({
    Key? key,
    required this.stateManager,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: stateManager.searchController,
        focusNode: stateManager.searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Поиск товаров...',
          prefixIcon: Icon(Icons.search),
          suffixIcon: stateManager.searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    stateManager.clearSearch();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        ),
        onChanged: (value) {
          stateManager.updateSearchQuery(value);
        },
        onSubmitted: (value) {
          stateManager.updateSearchQuery(value);
        },
      ),
    );
  }
}