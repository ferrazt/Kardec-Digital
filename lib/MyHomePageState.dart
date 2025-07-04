import 'package:flutter/material.dart';
import 'pdf_grid.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            pinned: true,
            stretch: true,
            expandedHeight: 180,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.asset(
                'assets/images/banner.jpg',
                fit: BoxFit.cover,
              ),
              stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
            ),
            actions: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
            ],
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverList(
            delegate: SliverChildListDelegate([
              const NetflixStylePDFList(), // seu carrossel por autor
              const SizedBox(height: 20),
            ]),
          ),
        ],
      ),
    );
  }
}
