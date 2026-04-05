import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';

class ChallengesWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final int friendsCount;
  final VoidCallback? onViewAllPressed;
  final VoidCallback? onContainerPressed;
  final VoidCallback? onFriendsPressed;
  final VoidCallback? onAddFriendPressed;

  const ChallengesWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.friendsCount,
    this.onViewAllPressed,
    this.onContainerPressed,
    this.onFriendsPressed,
    this.onAddFriendPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок челенжей
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Challenges',
              style: AppFonts.bodyTitleMedium.copyWith(
                color: AppColors.black100,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            GestureDetector(
              onTap: onViewAllPressed,
              child: Text(
                'VIEW ALL',
                style: AppFonts.bodyTitleMedium.copyWith(
                  color: AppColors.blue100,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 5),
        // Контейнер челенжей
        GestureDetector(
          onTap: onContainerPressed,
          child: Container(
            width: double.infinity,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.black10,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Основной контент
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      children: [
                        // Основной Row с контентом
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Левая часть - иконка и текст
                            Row(
                              children: [
                                // Иконка огня
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: AppColors.blue10Primary,
                                  ),
                                  child: Center(
                                    child: SvgPicture.asset('assets/icons/timer.svg'),
                                  ),
                                ),
                                SizedBox(width: 12),
                                // Колонка с текстом
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      title,
                                      style: AppFonts.bodyTitleMedium.copyWith(
                                        color: AppColors.black100,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 1),
                                    Text(
                                      subtitle,
                                      style: AppFonts.bodyAlternative.copyWith(
                                        color: AppColors.black40,
                                        fontSize: 11,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // Правая часть - колонка с кругами и подписью
                            _buildFriendsSection(),
                          ],
                        ),
                        SizedBox(height: 12),
                        // Прогресс-бар в той же колонке
                        Container(
                          width: double.infinity,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.black10,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: 3/7, // 3 из 7 дней
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.blue,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFriendsSection() {
    if (friendsCount == 0) {
      // Никого нет - иконка добавления друга
      return GestureDetector(
        onTap: onAddFriendPressed,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.blue10,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              Icons.add,
              color: AppColors.blue100,
              size: 20,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Круги с друзьями
        GestureDetector(
          onTap: onFriendsPressed,
          child: Container(
            width: 80,
            height: 20,
            child: Stack(
              alignment: Alignment.centerRight,
              children: _buildFriendCircles(),
            ),
          ),
        ),
        SizedBox(height: 1),
        // Подпись под кругами
        GestureDetector(
          onTap: onFriendsPressed,
          child: Text(
            friendsCount == 1 ? '1 friend joined' : '$friendsCount friends joined',
            style: AppFonts.bodyAlternative.copyWith(
              color: AppColors.black40,
              fontSize: 10,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFriendCircles() {
    List<Widget> circles = [];
    
    if (friendsCount <= 3) {
      // Показываем точное количество друзей
      for (int i = 0; i < friendsCount; i++) {
        circles.add(_buildFriendCircle(i, friendsCount));
      }
    } else {
      // Больше 3 друзей - показываем 2 круга и +N
      circles.add(_buildFriendCircle(0, friendsCount));
      circles.add(_buildFriendCircle(1, friendsCount));
      circles.add(_buildPlusCircle(friendsCount - 2));
    }
    
    return circles;
  }

  Widget _buildFriendCircle(int index, int totalCount) {
    // Цвета для кругов друзей
    List<Color> colors = [AppColors.blue10, AppColors.purple.withOpacity(0.2)];
    List<Color> innerColors = [AppColors.blue40, AppColors.purple];
    
    Color color = colors[index % colors.length];
    Color innerColor = innerColors[index % innerColors.length];
    
    // Позиционирование от правого края
    double rightOffset = index * 8.0; // 8px между кругами
    
    return Positioned(
      right: rightOffset,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 1,
          ),
        ),
        child: Center(
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: innerColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlusCircle(int additionalCount) {
    return Positioned(
      right: 16.0, // Третий круг
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: AppColors.orange10,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            '+$additionalCount',
            style: AppFonts.bodyAlternative.copyWith(
              color: AppColors.black100,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
