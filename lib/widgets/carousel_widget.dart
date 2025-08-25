import 'package:flutter/material.dart';

class CarouselWidget extends StatefulWidget {
  const CarouselWidget({
    required this.items,
    this.animationDuration = const Duration(milliseconds: 300),
    this.itemBorderRadius = 8.0,
    this.itemSpacing = 4.0,
    super.key,
  });

  /// 캐러셀 위젯
  final List<Widget> items;

  /// 애니메이션 동작시간
  final Duration animationDuration;

  /// 아이템 BorderRadius
  final double itemBorderRadius;

  /// 아이템 간 간격
  final double itemSpacing;

  @override
  State<CarouselWidget> createState() => _CarouselWidgetState();
}

class _CarouselWidgetState extends State<CarouselWidget>
    with TickerProviderStateMixin {
  /// viewportFraction
  /// 기본값: 1.0
  /// viewportFaction: 0.8 → 화면의 80%만 현재 페이지가 차지. 나머지 20%는 양쪽에 10%씩 분할됨.
  ///
  /// 레이아웃: [이전 10%] [현재 페이지 80%] [다음 10%]
  final PageController _pageController = PageController(viewportFraction: 0.8);

  /// 현재 페이지 인덱스
  int _currentIndex = 0;

  /// 애니메이션
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;

  @override
  void initState() {
    super.initState();

    /// 페이지의 수 만큼 애니메이션 컨트롤러 등록
    _animationControllers = List.generate(
      widget.items.length,
      (index) => AnimationController(
        duration: widget.animationDuration,
        vsync: this,
      ),
    );

    /// Tween<double>: double 타입의 값을 보간
    /// begin: 시작값
    /// end: 끝값
    /// .animate(): AnimationController와 연결
    ///
    /// - AnimationController의 value가 0.0일 때 → Tween 결과: 0.9
    /// - AnimationController의 value가 1.0일 때 → Tween 결과: 1.0
    /// - AnimationController의 value가 0.5일 때 → Tween 결과: 0.95
    ///
    /// controller.forward() 실행 시:
    /// 0.0초: scale = 0.9 (90% 크기)
    /// 0.15초: scale = 0.95 (95% 크기)
    /// 0.3초: scale = 1.0 (100% 크기)
    ///
    /// controller.reverse() 실행 시:
    /// 0.0초: scale = 1.0 (100% 크기)
    /// 0.15초: scale = 0.95 (95% 크기)
    /// 0.3초: scale = 0.9 (90% 크기)
    _scaleAnimations = _animationControllers
        .map((controller) => Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(
                parent: controller,
                curve: Curves.easeInOut, // 진행 속도 변화 패턴
              ),
            ))
        .toList();

    // 초기 페이지(인덱스 0) 애니메이션 시작
    _animationControllers[0].forward();
  }

  @override
  void dispose() {
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.horizontal,
      onPageChanged: (value) {
        // 이전 페이지 애니메이션 역방향 실행 (100% -> 90%)
        _animationControllers[_currentIndex].reverse();

        // 현재 페이지 인덱스 업데이트
        setState(() {
          _currentIndex = value;
        });

        // 새로운 현재 페이지 애니메이션 정방향 실행 (90% -> 100%)
        _animationControllers[_currentIndex].forward();

        debugPrint('$runtimeType :: onPageChanged :: $value');
      },
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        // margin: 위젯이 붙어보이지 않도록 간격(margin) 추가
        // 이전/다음 페이지는 현재 페이지의 90% 크기로 표시, 애니메이션 적용
        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: widget.itemSpacing,
          ),
          child: AnimatedBuilder(
            animation: _scaleAnimations[index],
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimations[index].value,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    widget.itemBorderRadius,
                  ),
                  child: widget.items[index],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
