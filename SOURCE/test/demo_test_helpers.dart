import 'package:wafa/domain/demo_connections.dart';
import 'package:wafa/domain/demo_models.dart';

DemoConnectionsRepository signedInConnections() {
  final connections = DemoConnectionsRepository();
  connections.signIn(DemoLoginMethod.apple, demoAmina.id);
  return connections;
}

DemoConnectionsRepository connectionsFor(
  DemoAgreementRepository repository, {
  String? ownerId,
}) {
  final connections = signedInConnections();
  for (final agreement in repository.agreements) {
    connections.registerAgreement(
      agreement.id,
      ownerId: ownerId ?? demoAmina.id,
      invitationsAllowed: agreement.status == AgreementStatus.draft,
    );
  }
  return connections;
}
