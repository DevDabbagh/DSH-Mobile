import re

file_path = 'lib/layers/main/presentation/main_navigation_screen.dart'

with open(file_path, 'r') as f:
    content = f.read()

# 1. Update the tabs to Home, Read, Academy, Discover, Profile
content = content.replace("label: l10n.filmsTab,", "label: l10n.actionRead, // using actionRead for now")
content = content.replace("Icons.article_outlined", "Icons.menu_book_outlined")
content = content.replace("Icons.article", "Icons.menu_book")

# 2. Update _NavItem widget to only show label when active
old_nav_item = '''  Widget build(BuildContext context) {
    final color = isActive ? AppColors.white : AppColors.textMuted;
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? activeIcon : icon,
            color: color,
            size: 24.w,
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }'''

new_nav_item = '''  Widget build(BuildContext context) {
    final color = isActive ? AppColors.white : AppColors.textMuted;
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isActive ? 6.w : 0),
            decoration: isActive 
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white.withValues(alpha: 0.2)),
                    color: AppColors.white.withValues(alpha: 0.05),
                  )
                : null,
            child: Icon(
              isActive ? activeIcon : icon,
              color: color,
              size: isActive ? 20.w : 24.w,
            ),
          ),
          if (isActive) ...[
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ]
        ],
      ),
    );
  }'''

content = content.replace(old_nav_item, new_nav_item)

with open(file_path, 'w') as f:
    f.write(content)

print("Updated main_navigation_screen.dart successfully!")
