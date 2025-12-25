import 'package:flutter/material.dart';

class SwipeController extends StatefulWidget {
  final List<Widget> pages;
  final List<String> pageTitles;
  final int initialPage;

  const SwipeController({
    Key? key,
    required this.pages,
    required this.pageTitles,
    this.initialPage = 0,
  }) : super(key: key);

  @override
  _SwipeControllerState createState() => _SwipeControllerState();
}

class _SwipeControllerState extends State<SwipeController> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Page Indicators
        Container(
          margin: EdgeInsets.only(top: 20, bottom: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.pages.length, (index) {
              return GestureDetector(
                onTap: () => _pageController.animateToPage(
                  index,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _currentPage == index 
                        ? Colors.cyan
                        : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ),
        // Page Title
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Text(
            widget.pageTitles[_currentPage],
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Colors.white,
            ),
          ),
        ),
        // Swipe Pages
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: widget.pages,
          ),
        ),
      ],
    );
  }
}