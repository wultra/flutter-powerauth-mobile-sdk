
/// ### iOS specific
/// 
/// The `PowerAuthExternalPendingOperationType` defines types of operation
/// started in another application that share activation data.
enum PowerAuthExternalPendingOperationType {
  activation,
  protocolUpgrade,
}

/// ### iOS specific
/// 
/// The `PowerAuthExternalPendingOperation` interface contains data that can identify an external
/// application that started the critical operation.
class PowerAuthExternalPendingOperation {
    /// Type of operation running in another application.
    PowerAuthExternalPendingOperationType externalOperationType;
    /// Identifier of external application that started the operation. This is the same identifier
    /// you provided to `PowerAuthSharingConfiguration` during the PowerAuth initialization.
    String externalApplicationId;

    PowerAuthExternalPendingOperation._({
      required this.externalOperationType,
      required this.externalApplicationId,
    });

    factory PowerAuthExternalPendingOperation.fromMap(Map map) {
      return PowerAuthExternalPendingOperation._(
        externalOperationType: PowerAuthExternalPendingOperationType.values.firstWhere(
          (e) => e.toString().split('.').last == map['externalOperationType'],
          orElse: () => PowerAuthExternalPendingOperationType.activation,
        ),
        externalApplicationId: map['externalApplicationId'] as String,
      );
    }
}