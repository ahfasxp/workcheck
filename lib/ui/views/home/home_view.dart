import 'dart:io';

import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'home_viewmodel.dart';

class HomeView extends StackedView<HomeViewModel> {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    HomeViewModel viewModel,
    Widget? child,
  ) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 50),
              const Text(
                'Welcome to WorkCheck',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton(
                onPressed: viewModel.timer != null
                    ? viewModel.onStopWork
                    : viewModel.onStartWork,
                child: viewModel.busy(viewModel)
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(),
                      )
                    : Text(
                        viewModel.timer != null ? 'Stop Work' : 'Start Work'),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: width * 0.7,
                      child: GridView.count(
                        crossAxisCount: 4,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 16 / 9,
                        children: List.generate(
                          viewModel.screenshots.length,
                          (index) => Stack(
                            children: [
                              AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Image.file(
                                  File(viewModel.screenshots[index]),
                                  fit: BoxFit.fill,
                                ),
                              ),
                              // name file
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  color: Colors.black.withOpacity(0.5),
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    viewModel.screenshots[index]
                                        .split('/')
                                        .last
                                        .split('.')
                                        .first,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: width * 0.3,
                      child: Column(
                        children: [
                          const Text(
                            'Prediction Results',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: viewModel.predictionResults.length,
                              itemBuilder: (context, index) {
                                final predictionResult = viewModel
                                    .predictionResults.reversed
                                    .elementAt(index);

                                return ListTile(
                                  title: Text(
                                    predictionResult.createdAt.toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    predictionResult.description,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  HomeViewModel viewModelBuilder(
    BuildContext context,
  ) =>
      HomeViewModel();

  @override
  void onViewModelReady(
    HomeViewModel viewModel,
  ) {
    viewModel.init();
    super.onViewModelReady(viewModel);
  }
}
