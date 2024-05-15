import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class OnboardingYoutubeCover extends StatelessWidget {
  const OnboardingYoutubeCover({
    super.key,
    required this.url,
  });

  final String url;

  String getCoverUrlFromYoutubeVideoUrl(String url) {
    final videoId = url.split('v=')[1];
    return 'https://img.youtube.com/vi/$videoId/0.jpg';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.center,
          child: Image.network(
            getCoverUrlFromYoutubeVideoUrl(url),
            fit: BoxFit.scaleDown,
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: InkWell(
            onTap: () {
              try {
                launchUrl(Uri.parse(url));
              } catch (e, s) {
                Sentry.captureException(
                  e,
                  stackTrace: s,
                );
              }
            },
            child: Container(
              width: 70,
              height: 50,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(202, 29, 32, 1.0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.play_arrow,
                size: 32,
                color: Colors.white,
              ),
            ),
          ),
        )
      ],
    );
  }
}
