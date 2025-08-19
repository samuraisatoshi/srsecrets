# SRSecrets Responsive Design Guide

## Overview

This guide provides comprehensive documentation for implementing responsive design patterns in the SRSecrets application. Our responsive approach ensures optimal user experience across all device form factors, from smartphones to tablets to desktop computers, while maintaining the premium crypto wallet aesthetic and security-focused interactions.

## Design Philosophy

### Device-First Approach
- **Mobile-First Design**: Core experience optimized for smartphones
- **Progressive Enhancement**: Additional features unlock on larger screens
- **Context-Aware Layout**: Adapt to user's primary interaction method
- **Consistent Identity**: Brand and security focus maintained across all sizes

### Adaptive vs. Responsive
- **Adaptive Components**: Discrete layouts for specific breakpoints
- **Responsive Elements**: Fluid scaling within breakpoint ranges
- **Hybrid Strategy**: Combined approach for optimal user experience
- **Performance Focused**: Efficient rendering across all device types

## Breakpoint System

### Core Breakpoints
Our responsive system uses a three-tier breakpoint approach:

```dart
class ResponsiveBreakpoints {
  // Mobile devices (phones in portrait/landscape)
  static const double mobile = 600.0;
  
  // Tablet devices (small tablets, large phones in landscape)
  static const double tablet = 840.0;
  
  // Desktop devices (large tablets, laptops, desktops)
  static const double desktop = 1200.0;
  
  // Extended desktop (wide monitors, multiple displays)
  static const double wide = 1600.0;
}

class ResponsiveHelper {
  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < ResponsiveBreakpoints.mobile;
  }
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= ResponsiveBreakpoints.mobile && 
           width < ResponsiveBreakpoints.desktop;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= ResponsiveBreakpoints.desktop;
  }
}
```

### Breakpoint Selection Rationale
- **600dp Mobile Threshold**: Material Design recommendation for compact layouts
- **840dp Tablet Threshold**: Optimal for dual-pane layouts and extended navigation
- **1200dp Desktop Threshold**: Comfortable reading width with sidebar navigation
- **1600dp Wide Threshold**: Ultra-wide monitor support with enhanced layouts

## Layout Patterns

### Navigation Adaptation

#### Mobile Navigation (< 600dp)
Bottom navigation bar with essential actions:

```dart
class MobileNavigation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.add_circle_outline),
          selectedIcon: Icon(Icons.add_circle),
          label: 'Create',
        ),
        NavigationDestination(
          icon: Icon(Icons.restore_outlined),
          selectedIcon: Icon(Icons.restore),
          label: 'Restore',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
      selectedIndex: _selectedIndex,
      onDestinationSelected: _handleNavigation,
    );
  }
}
```

#### Tablet Navigation (600dp - 1200dp)
Navigation rail with compact labels:

```dart
class TabletNavigation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _handleNavigation,
      labelType: NavigationRailLabelType.selected,
      backgroundColor: Theme.of(context).colorScheme.surface,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('Home'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.add_circle_outline),
          selectedIcon: Icon(Icons.add_circle),
          label: Text('Create'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.restore_outlined),
          selectedIcon: Icon(Icons.restore),
          label: Text('Restore'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
      ],
    );
  }
}
```

#### Desktop Navigation (≥ 1200dp)
Extended navigation rail with full labels and additional actions:

```dart
class DesktopNavigation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _handleNavigation,
      labelType: NavigationRailLabelType.all,
      minWidth: 200,
      backgroundColor: Theme.of(context).colorScheme.surface,
      leading: Column(
        children: [
          const SizedBox(height: 24),
          Icon(
            Icons.security,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            'SRSecrets',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
      destinations: // Extended navigation items
    );
  }
}
```

### Content Layout Adaptation

#### PIN Entry Responsive Design
Adaptive PIN input that scales and repositions based on screen size:

```dart
class ResponsivePinEntry extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth >= 600 && 
                        constraints.maxWidth < 1200;
        
        if (isMobile) {
          return _buildMobileLayout(context);
        } else if (isTablet) {
          return _buildTabletLayout(context);
        } else {
          return _buildDesktopLayout(context);
        }
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        // PIN dots centered above keypad
        _buildPinDots(dotSize: 20.0, spacing: 12.0),
        const SizedBox(height: 40),
        // Full-width keypad
        _buildKeypad(keySize: 70.0, gridSpacing: 16.0),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPinDots(dotSize: 24.0, spacing: 16.0),
              const SizedBox(height: 32),
              _buildSecurityIndicator(),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: _buildKeypad(keySize: 80.0, gridSpacing: 20.0),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                _buildPinDots(dotSize: 28.0, spacing: 20.0),
                const SizedBox(height: 40),
                _buildSecurityBadge(),
              ],
            ),
          ),
          const SizedBox(width: 80),
          SizedBox(
            width: 320,
            child: _buildKeypad(keySize: 88.0, gridSpacing: 24.0),
          ),
        ],
      ),
    );
  }
}
```

### Form Layout Adaptation

#### Secret Creation Form
Responsive form that adapts field arrangement based on available space:

```dart
class ResponsiveSecretForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTabletPortrait = constraints.maxWidth >= 600 && 
                                constraints.maxWidth < 840;
        final isTabletLandscape = constraints.maxWidth >= 840 && 
                                 constraints.maxWidth < 1200;
        final isDesktop = constraints.maxWidth >= 1200;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: _getHorizontalPadding(constraints.maxWidth),
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: _getMaxContentWidth(constraints.maxWidth),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                SizedBox(height: isMobile ? 32 : 48),
                
                if (isMobile) 
                  _buildMobileForm(context)
                else if (isTabletPortrait)
                  _buildTabletPortraitForm(context)
                else if (isTabletLandscape)
                  _buildTabletLandscapeForm(context)
                else
                  _buildDesktopForm(context),
              ],
            ),
          ),
        );
      },
    );
  }

  double _getHorizontalPadding(double width) {
    if (width < 600) return 16.0;
    if (width < 840) return 32.0;
    if (width < 1200) return 48.0;
    return 64.0;
  }

  double _getMaxContentWidth(double width) {
    if (width < 600) return double.infinity;
    if (width < 840) return 600.0;
    if (width < 1200) return 800.0;
    return 1000.0;
  }
}
```

## Component Responsive Patterns

### Responsive Cards

#### Premium Security Card Adaptation
Cards that adapt size, spacing, and layout based on screen real estate:

```dart
class ResponsivePremiumCard extends StatelessWidget {
  final Widget child;
  final String? title;
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardPadding = _getCardPadding(constraints.maxWidth);
        final borderRadius = _getBorderRadius(constraints.maxWidth);
        final elevation = _getElevation(constraints.maxWidth);
        
        return PremiumSecurityCard(
          title: title,
          padding: cardPadding,
          borderRadius: borderRadius,
          elevation: elevation,
          child: child,
        );
      },
    );
  }

  EdgeInsets _getCardPadding(double width) {
    if (width < 600) return const EdgeInsets.all(16);
    if (width < 840) return const EdgeInsets.all(20);
    if (width < 1200) return const EdgeInsets.all(24);
    return const EdgeInsets.all(28);
  }

  double _getBorderRadius(double width) {
    if (width < 600) return 16.0;
    if (width < 840) return 18.0;
    if (width < 1200) return 20.0;
    return 22.0;
  }

  double _getElevation(double width) {
    if (width < 600) return 2.0;
    if (width < 840) return 4.0;
    if (width < 1200) return 6.0;
    return 8.0;
  }
}
```

### Responsive Typography

#### Adaptive Text Scaling
Text that scales appropriately across different screen sizes:

```dart
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  final int? maxLines;
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaleFactor = _getTextScaleFactor(constraints.maxWidth);
        final adaptiveStyle = (baseStyle ?? 
            Theme.of(context).textTheme.bodyMedium)?.copyWith(
          fontSize: (baseStyle?.fontSize ?? 14) * scaleFactor,
        );

        return Text(
          text,
          style: adaptiveStyle,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }

  double _getTextScaleFactor(double width) {
    if (width < 600) return 1.0;      // Mobile baseline
    if (width < 840) return 1.1;      // Tablet portrait 10% larger
    if (width < 1200) return 1.15;    // Tablet landscape 15% larger
    return 1.2;                       // Desktop 20% larger
  }
}
```

## Screen-Specific Responsive Implementations

### Home Screen Responsive Layout

#### Multi-Device Navigation Pattern
```dart
class ResponsiveHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
        return Scaffold(
          body: Row(
            children: [
              // Navigation rail for tablet/desktop
              if (!isMobile) 
                ResponsiveNavigation(width: constraints.maxWidth),
              
              // Main content area
              Expanded(
                child: Column(
                  children: [
                    _buildAppBar(context, isMobile),
                    Expanded(
                      child: _buildMainContent(context, constraints),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Bottom navigation for mobile only
          bottomNavigationBar: isMobile 
              ? MobileNavigation()
              : null,
        );
      },
    );
  }

  Widget _buildMainContent(BuildContext context, BoxConstraints constraints) {
    final isMobile = constraints.maxWidth < 600;
    final isTablet = constraints.maxWidth >= 600 && 
                    constraints.maxWidth < 1200;
    final isDesktop = constraints.maxWidth >= 1200;

    if (isMobile) {
      return _buildMobileContent(context);
    } else if (isTablet) {
      return _buildTabletContent(context);
    } else {
      return _buildDesktopContent(context);
    }
  }
}
```

### Create Secret Screen Responsive Enhancement

#### Form Field Arrangement
```dart
class ResponsiveCreateSecretScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: _getHorizontalPadding(constraints.maxWidth),
              vertical: 24,
            ),
            child: _buildResponsiveForm(context, constraints),
          );
        },
      ),
    );
  }

  Widget _buildResponsiveForm(BuildContext context, BoxConstraints constraints) {
    final isTabletLandscape = constraints.maxWidth >= 840 && 
                             constraints.maxWidth < 1200;
    final isDesktop = constraints.maxWidth >= 1200;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: isDesktop ? 800 : double.infinity,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SecretFormHeader(),
          const SizedBox(height: 32),
          
          if (isTabletLandscape || isDesktop) ...[
            // Side-by-side layout for tablets/desktop
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildSecretInput(context),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: _buildThresholdConfig(context),
                ),
              ],
            ),
          ] else ...[
            // Vertical layout for mobile/tablet portrait
            _buildSecretInput(context),
            const SizedBox(height: 24),
            _buildThresholdConfig(context),
          ],
          
          const SizedBox(height: 32),
          _buildActionButtons(context, constraints.maxWidth),
        ],
      ),
    );
  }
}
```

### Reconstruct Secret Screen Grid Layout

#### Dynamic Share Input Grid
```dart
class ResponsiveReconstructScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final shareCount = _getShareCount();
          final gridColumns = _getGridColumns(constraints.maxWidth, shareCount);
          
          return SingleChildScrollView(
            padding: EdgeInsets.all(_getPadding(constraints.maxWidth)),
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 32),
                
                if (gridColumns == 1) ...[
                  // Vertical list for mobile
                  ..._buildShareInputs().map((input) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: input,
                  )),
                ] else ...[
                  // Grid layout for tablets/desktop
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridColumns,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: shareCount,
                    itemBuilder: (context, index) => _buildShareInputs()[index],
                  ),
                ],
                
                const SizedBox(height: 32),
                _buildReconstructButton(context, constraints.maxWidth),
              ],
            ),
          );
        },
      ),
    );
  }

  int _getGridColumns(double width, int shareCount) {
    if (width < 600) return 1;        // Mobile: single column
    if (width < 840) return 2;        // Tablet portrait: 2 columns
    if (shareCount <= 4) return 2;    // Tablet landscape: 2 columns if ≤4 shares
    if (shareCount <= 6) return 3;    // Desktop: 3 columns if ≤6 shares
    return 4;                         // Wide desktop: 4 columns maximum
  }
}
```

## Cross-Platform Considerations

### Platform-Specific Adaptations

#### iOS Specific Enhancements
```dart
class iOSResponsiveEnhancements {
  static Widget buildSafeAreaWrapper(Widget child) {
    return SafeArea(
      child: child,
      // Handle dynamic island and notches
      minimum: const EdgeInsets.only(top: 8),
    );
  }

  static EdgeInsets getResponsivePadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final safeArea = mediaQuery.padding;
    
    return EdgeInsets.only(
      left: math.max(16, safeArea.left),
      right: math.max(16, safeArea.right),
      bottom: math.max(16, safeArea.bottom),
    );
  }
}
```

#### Android Specific Enhancements
```dart
class AndroidResponsiveEnhancements {
  static Widget buildNavigationWrapper(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaQuery = MediaQuery.of(context);
        final hasNavigationBar = mediaQuery.padding.bottom > 0;
        
        return Padding(
          padding: EdgeInsets.only(
            bottom: hasNavigationBar ? 0 : 16,
          ),
          child: child,
        );
      },
    );
  }
}
```

### Foldable Device Support

#### Dual-Screen Layout Optimization
```dart
class FoldableResponsiveLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Detect foldable device characteristics
        final aspectRatio = constraints.maxWidth / constraints.maxHeight;
        final isUltraWide = aspectRatio > 2.0;
        final isSquarish = aspectRatio > 0.8 && aspectRatio < 1.2;
        
        if (isUltraWide) {
          return _buildDualPaneLayout(context);
        } else if (isSquarish) {
          return _buildFoldedLayout(context);
        } else {
          return _buildStandardLayout(context);
        }
      },
    );
  }

  Widget _buildDualPaneLayout(BuildContext context) {
    return Row(
      children: [
        // Left pane: PIN entry
        Expanded(
          child: PremiumPinInput(
            onCompleted: _handlePinCompleted,
          ),
        ),
        
        // Center divider
        Container(
          width: 1,
          color: Theme.of(context).dividerColor,
        ),
        
        // Right pane: Security information
        Expanded(
          child: SecurityInformation(),
        ),
      ],
    );
  }
}
```

## Performance Optimization

### Efficient Responsive Rendering

#### Layout Caching Strategy
```dart
class ResponsiveLayoutCache {
  static final Map<String, Widget> _layoutCache = {};
  
  static Widget getCachedLayout(
    String key,
    double width,
    WidgetBuilder builder,
  ) {
    final cacheKey = '${key}_${width.floor()}';
    
    return _layoutCache[cacheKey] ??= builder();
  }
  
  static void clearCache() {
    _layoutCache.clear();
  }
}
```

#### Conditional Widget Building
```dart
class ConditionalBuilder extends StatelessWidget {
  final Widget mobileWidget;
  final Widget? tabletWidget;
  final Widget? desktopWidget;
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        if (width >= 1200 && desktopWidget != null) {
          return desktopWidget!;
        } else if (width >= 600 && tabletWidget != null) {
          return tabletWidget!;
        } else {
          return mobileWidget;
        }
      },
    );
  }
}
```

### Memory Management

#### Responsive Image Loading
```dart
class ResponsiveImageProvider {
  static ImageProvider getOptimizedImage(
    String basePath,
    double screenWidth,
  ) {
    String suffix;
    if (screenWidth < 600) {
      suffix = '_mobile';
    } else if (screenWidth < 1200) {
      suffix = '_tablet';
    } else {
      suffix = '_desktop';
    }
    
    return AssetImage('$basePath$suffix.png');
  }
}
```

## Testing Responsive Layouts

### Widget Testing for Multiple Sizes

#### Responsive Widget Tests
```dart
group('Responsive Layout Tests', () {
  testWidgets('PIN input adapts to mobile size', (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 812)); // iPhone
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResponsivePinEntry(),
        ),
      ),
    );
    
    // Verify mobile layout characteristics
    expect(find.byType(Column), findsOneWidget);
    expect(find.byType(Row), findsNothing);
    
    // Check keypad button size
    final keyButton = tester.widget<Container>(
      find.byType(Container).first,
    );
    expect(keyButton.constraints?.maxWidth, equals(70.0));
  });

  testWidgets('PIN input adapts to tablet size', (tester) async {
    await tester.binding.setSurfaceSize(const Size(768, 1024)); // iPad
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResponsivePinEntry(),
        ),
      ),
    );
    
    // Verify tablet layout characteristics
    expect(find.byType(Row), findsOneWidget);
    
    // Check larger keypad buttons
    final keyButton = tester.widget<Container>(
      find.byType(Container).first,
    );
    expect(keyButton.constraints?.maxWidth, equals(80.0));
  });

  testWidgets('Form layout responds to screen width', (tester) async {
    // Test mobile layout
    await tester.binding.setSurfaceSize(const Size(375, 812));
    await tester.pumpWidget(TestApp());
    
    // Should have vertical layout
    expect(find.byType(Column), findsWidgets);
    
    // Test tablet landscape layout
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    await tester.pumpAndSettle();
    
    // Should have horizontal layout
    expect(find.byType(Row), findsWidgets);
  });
});
```

### Golden File Testing for Responsive Layouts

#### Multi-Size Golden Tests
```dart
group('Responsive Golden Tests', () {
  testWidgets('Home screen golden files', (tester) async {
    final homeScreen = MaterialApp(
      theme: PremiumTheme.getDarkTheme(),
      home: ResponsiveHomeScreen(),
    );
    
    // Mobile size
    await tester.binding.setSurfaceSize(const Size(375, 812));
    await tester.pumpWidget(homeScreen);
    await tester.pumpAndSettle();
    
    await expectLater(
      find.byType(ResponsiveHomeScreen),
      matchesGoldenFile('home_screen_mobile.png'),
    );
    
    // Tablet size
    await tester.binding.setSurfaceSize(const Size(768, 1024));
    await tester.pumpAndSettle();
    
    await expectLater(
      find.byType(ResponsiveHomeScreen),
      matchesGoldenFile('home_screen_tablet.png'),
    );
    
    // Desktop size
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester.pumpAndSettle();
    
    await expectLater(
      find.byType(ResponsiveHomeScreen),
      matchesGoldenFile('home_screen_desktop.png'),
    );
  });
});
```

## Accessibility in Responsive Design

### Responsive Touch Targets

#### Adaptive Touch Target Sizing
```dart
class ResponsiveTouchTarget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Larger touch targets on smaller screens for finger navigation
        final minSize = constraints.maxWidth < 600 ? 48.0 : 44.0;
        
        return GestureDetector(
          onTap: onTap,
          child: Container(
            constraints: BoxConstraints(
              minWidth: minSize,
              minHeight: minSize,
            ),
            child: child,
          ),
        );
      },
    );
  }
}
```

### Screen Reader Adaptation

#### Context-Aware Semantic Labels
```dart
class ResponsiveSemantics extends StatelessWidget {
  final Widget child;
  final String mobileLabel;
  final String tabletLabel;
  final String desktopLabel;
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        String label;
        if (constraints.maxWidth < 600) {
          label = mobileLabel;
        } else if (constraints.maxWidth < 1200) {
          label = tabletLabel;
        } else {
          label = desktopLabel;
        }
        
        return Semantics(
          label: label,
          child: child,
        );
      },
    );
  }
}
```

## Best Practices

### Do's
- ✅ Use LayoutBuilder for constraint-based responsive decisions
- ✅ Implement progressive enhancement from mobile to desktop
- ✅ Cache expensive layout calculations for performance
- ✅ Test responsive behavior with automated widget tests
- ✅ Maintain consistent visual hierarchy across all breakpoints
- ✅ Adapt touch targets appropriately for input method
- ✅ Use semantic breakpoints that match user mental models

### Don'ts
- ❌ Don't hardcode pixel values without responsive consideration
- ❌ Don't assume desktop users want mobile-sized touch targets
- ❌ Don't ignore platform-specific design conventions
- ❌ Don't create responsive layouts that break accessibility
- ❌ Don't over-engineer responsive solutions for simple components
- ❌ Don't forget to test on actual devices, not just emulators
- ❌ Don't sacrifice security for responsive convenience

## Future Enhancements

### Planned Responsive Features
1. **AI-Powered Layout Optimization**: Machine learning to optimize layouts based on user behavior
2. **Contextual Interface Adaptation**: Adjust UI density based on usage context
3. **Multi-Window Support**: Enhanced layouts for split-screen and picture-in-picture modes
4. **Gesture-Responsive Design**: Layouts that adapt to user's preferred interaction patterns
5. **Environmental Responsive Design**: Adapt to lighting conditions, battery level, and connectivity

### Emerging Technologies
- **Foldable Display APIs**: Enhanced support for flexible displays
- **Multi-Screen Coordination**: Seamless experience across multiple connected devices
- **AR/VR Interface Adaptation**: Responsive principles applied to spatial interfaces
- **Voice-First Responsive Design**: Layouts that adapt to voice interaction patterns

---

*This responsive design guide ensures the SRSecrets application provides an optimal user experience across all devices while maintaining security, accessibility, and performance standards.*