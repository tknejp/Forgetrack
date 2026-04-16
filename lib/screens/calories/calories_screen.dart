import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/calorie_entry.dart';
import '../../providers/calorie_provider.dart';

class CaloriesScreen extends StatefulWidget {
  const CaloriesScreen({super.key});

  @override
  State<CaloriesScreen> createState() => _CaloriesScreenState();
}

class _CaloriesScreenState extends State<CaloriesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalorieProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalorický deník'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Hledat potravinu…',
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      context.read<CalorieProvider>().clearSearch();
                    },
                  ),
              ],
              onSubmitted: (q) =>
                  context.read<CalorieProvider>().searchFood(q),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
      ),
      body: provider.searchResults.isNotEmpty || provider.isSearching
          ? _SearchResultsList(provider: provider)
          : _DailyLog(provider: provider),
    );
  }
}

class _SearchResultsList extends StatelessWidget {
  final CalorieProvider provider;

  const _SearchResultsList({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.searchResults.isEmpty) {
      return const Center(child: Text('Žádné výsledky.'));
    }

    return ListView.builder(
      itemCount: provider.searchResults.length,
      itemBuilder: (_, i) =>
          _FoodResultTile(food: provider.searchResults[i]),
    );
  }
}

class _FoodResultTile extends StatelessWidget {
  final FoodItem food;

  const _FoodResultTile({required this.food});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(food.name),
      subtitle: Text('${food.kcalPer100g.round()} kcal / 100 g'),
      trailing: IconButton(
        icon: const Icon(Icons.add_circle_outline),
        onPressed: () => _showAddDialog(context, food),
      ),
    );
  }

  void _showAddDialog(BuildContext context, FoodItem food) {
    double grams = 100;
    MealType meal = MealType.obed;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(food.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<MealType>(
                value: meal,
                decoration: const InputDecoration(labelText: 'Jídlo'),
                items: MealType.values
                    .map((m) =>
                        DropdownMenuItem(value: m, child: Text(m.label)))
                    .toList(),
                onChanged: (v) => setS(() => meal = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: '100',
                decoration: const InputDecoration(
                    labelText: 'Gramy', suffixText: 'g'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) => grams = double.tryParse(v) ?? grams,
              ),
              const SizedBox(height: 8),
              Text(
                '≈ ${(food.kcalPer100g * grams / 100).round()} kcal',
                style: Theme.of(ctx).textTheme.bodyLarge,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Zrušit')),
            FilledButton(
              onPressed: () {
                context.read<CalorieProvider>().addEntry(
                      CalorieEntry(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        date: DateTime.now(),
                        meal: meal,
                        food: food,
                        grams: grams,
                      ),
                    );
                Navigator.pop(ctx);
              },
              child: const Text('Přidat'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyLog extends StatelessWidget {
  final CalorieProvider provider;

  const _DailyLog({required this.provider});

  @override
  Widget build(BuildContext context) {
    final log = provider.todayLog;

    if (log.isEmpty) {
      final muted = Theme.of(context).colorScheme.onSurfaceVariant;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant, size: 64, color: muted),
            const SizedBox(height: 12),
            Text(
              'Dnes ještě žádné záznamy.\nVyhledej potravinu výše.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: log.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final entry = log[i];
        return ListTile(
          title: Text(entry.food.name),
          subtitle: Text('${entry.meal.label} · ${entry.grams.round()} g'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${entry.kcal.round()} kcal',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600)),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () =>
                    context.read<CalorieProvider>().removeEntry(entry.id),
              ),
            ],
          ),
        );
      },
    );
  }
}
