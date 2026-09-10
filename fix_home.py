import os
import re

file_path = 'lib/layers/home/presentation/home_page.dart'

with open(file_path, 'r') as f:
    content = f.read()

# 1. PageController viewportFraction -> 0.60
content = content.replace('PageController(viewportFraction: 0.85)', 'PageController(viewportFraction: 0.60)')

# 2. Hero cards border radius -> 6.r
content = content.replace('borderRadius: BorderRadius.circular(32.r)', 'borderRadius: BorderRadius.circular(6.r)')

# 3. View more button border radius and icon
content = content.replace('borderRadius: BorderRadius.circular(100.r)', 'borderRadius: BorderRadius.circular(6.r)')
content = content.replace('Icons.arrow_forward, color: AppColors.mainPurple, size: 14.w', 'Icons.add, color: AppColors.mainPurple, size: 14.w')

# 4. Search Animation Texts
content = content.replace('"Search Course..",\n    "Search Content..",\n    "Search Film..",\n    "Search Event.."', '"Course..",\n    "Content..",\n    "Film..",\n    "Event.."')

# 5. Search Animation Build Method
old_build = '''  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          _currentText,
          style: TextStyle(color: AppColors.textMuted, fontSize: 14.sp),
        ),
        _BlinkingCursor(),
      ],
    );
  }'''

new_build = '''  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          "Search ",
          style: TextStyle(color: AppColors.textMuted, fontSize: 14.sp),
        ),
        Text(
          _currentText,
          style: TextStyle(color: AppColors.textMuted, fontSize: 14.sp),
        ),
        _BlinkingCursor(),
      ],
    );
  }'''
content = content.replace(old_build, new_build)

# 6. Add Shadows and Grayscale to Films, Studio, Academy, In Focus
# We need to find the BoxDecorations of those lists and add shadows.
# Films: 
# width: 140.w,\n                decoration: BoxDecoration(\n                  borderRadius: BorderRadius.circular(16.r),\n                  image: const DecorationImage(
# We need to change DecorationImage to CachedNetworkImage for all of them ideally, but the user just asked for shadows and b&w filter.

with open(file_path, 'w') as f:
    f.write(content)

print("Script generated")
