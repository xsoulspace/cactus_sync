import 'package:cactus_sync_client/src/graphql/DefaultGqlOperations.dart';
import 'package:flutter/material.dart';
import 'package:gql_http_link/gql_http_link.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

/// This config required to init GraphqlRunner
/// Under the hood it uses default ferry with hive and hive_flutter setup
/// as described in [ferry setup](https://ferrygraphql.com/docs/setup)
///
/// You can provide a [hiveSubDir] - where the hive boxes should be stored.
class GraphqlRunnerConfig {
  String? hiveSubDir;
  HttpLink httpLink;
  AuthLink authLink;
  bool alwaysRebroadcast;
  DefaultPolicies? defaultPolicies;
  GraphQLCache? cache;
  FetchPolicy? defaultFetchPolicy;
  GraphqlRunnerConfig(
      {this.hiveSubDir,
      required this.authLink,
      required this.httpLink,
      this.defaultPolicies,
      this.alwaysRebroadcast = false,
      this.cache,
      this.defaultFetchPolicy});
}

///To init this class use `GraphqlRunner.init(...)`
///
///to use ValueNotifier & Provider use recommendations from Grapphql package:
///https://pub.dev/packages/graphql_flutter/versions/5.0.0-nullsafety.2
///
class GraphqlRunner {
  GraphQLClient client;
  ValueNotifier<GraphQLClient> clientNotifier;
  FetchPolicy defaultFetchPolicy;
  GraphqlRunner(
      {required this.client,
      required this.clientNotifier,
      this.defaultFetchPolicy = FetchPolicy.networkOnly});

  static Future<GraphqlRunner> init(
      {required GraphqlRunnerConfig config}) async {
    await initHiveForFlutter(subDir: config.hiveSubDir);

    final Link link = config.authLink.concat(config.httpLink);
    final client = GraphQLClient(
        link: link,
        cache: config.cache ??
            GraphQLCache(
              store: HiveStore(),
            ),
        alwaysRebroadcast: config.alwaysRebroadcast,
        defaultPolicies: config.defaultPolicies);
    ValueNotifier<GraphQLClient> clientNotifier = ValueNotifier(client);
    var runner = GraphqlRunner(client: client, clientNotifier: clientNotifier);

    return runner;
  }

  execute<TType, TVariables, TQueryResult>(
      {query, variableValues, operationType}) async {
    switch (operationType) {
      case DefaultGqlOperationType.create:
      case DefaultGqlOperationType.update:
      case DefaultGqlOperationType.remove:
        return await this.client.mutate(
            MutationOptions(document: query, variables: variableValues));
      case DefaultGqlOperationType.get_:
      case DefaultGqlOperationType.find:
        return await this.client.query(QueryOptions(
            document: query,
            variables: variableValues,
            fetchPolicy: defaultFetchPolicy));
    }
  }
}
