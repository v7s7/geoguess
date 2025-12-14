import 'package:flutter/material.dart';
import 'package:geoguess_flags/l10n/app_localizations.dart';
import '../widgets/result_card.dart';

class ResultPage extends StatelessWidget {
  final int score;
  final int playedQuestions;
  final int totalQuestions;

  const ResultPage({
    super.key,
    required this.score,
    required this.playedQuestions,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maxScore = playedQuestions * 100;
    final percentage = maxScore > 0 ? (score / maxScore) : 0.0;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.gameOver), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
            const SizedBox(height: 24),
            Text(l10n.finalScore, style: Theme.of(context).textTheme.headlineMedium),
            Text(
              "$score",
              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                ResultCard(
                  icon: Icons.question_answer,
                  value: "$playedQuestions / $totalQuestions",
                  label: l10n.question,
                  color: Colors.blue,
                ),
                const SizedBox(width: 16),
                ResultCard(
                  icon: Icons.percent,
                  value: "${(percentage * 100).toInt()}%",
                  label: l10n.score,
                  color: percentage > 0.5 ? Colors.green : Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.backToHome),
              ),
            ),
          ],
        ),
      ),
    );
  }
}