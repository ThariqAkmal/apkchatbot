import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSendMessage;
  final String selectedModel;
  final List<String> availableModels;
  final Function(String) onModelChanged;

  const MessageInput({
    Key? key,
    required this.controller,
    required this.onSendMessage,
    required this.selectedModel,
    required this.availableModels,
    required this.onModelChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 6, 16, 16), // Reduced top padding
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBackground.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Model Selection Dropdown - Top positioned
            Container(
              width: double.infinity,
              height: 36,
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              decoration: BoxDecoration(
                color: AppColors.primaryBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.secondaryTextDark.withValues(alpha: 0.3),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedModel,
                  isExpanded: true,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.secondaryTextLight,
                    size: 16,
                  ),
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  dropdownColor: AppColors.primaryBackground,
                  isDense: true,
                  menuMaxHeight: 200,
                  items:
                      availableModels.map((String model) {
                        return DropdownMenuItem<String>(
                          value: model,
                          child: Text(
                            model,
                            style: TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 13,
                            ),
                          ),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      onModelChanged(newValue);
                    }
                  },
                ),
              ),
            ),
            // Chat Input Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.secondaryTextDark),
                    ),
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: 'Ketik pesan Anda...',
                        hintStyle: TextStyle(
                          color: AppColors.secondaryTextLight,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      style: TextStyle(color: AppColors.primaryText),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSendMessage(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    onPressed: onSendMessage,
                    icon: Icon(Icons.send, color: AppColors.primaryText),
                    iconSize: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
