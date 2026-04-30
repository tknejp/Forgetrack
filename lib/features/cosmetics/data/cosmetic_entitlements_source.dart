class CosmeticEntitlement {
  const CosmeticEntitlement({
    required this.cosmeticId,
    required this.sourceType,
    this.sourceId,
  });

  final String cosmeticId;
  final String sourceType;
  final String? sourceId;
}

abstract class CosmeticEntitlementsSource {
  Future<List<CosmeticEntitlement>> loadForUser(String uid);
}

class NoopCosmeticEntitlementsSource implements CosmeticEntitlementsSource {
  const NoopCosmeticEntitlementsSource();

  @override
  Future<List<CosmeticEntitlement>> loadForUser(String uid) async {
    return const [];
  }
}
