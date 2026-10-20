import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dwell/features/my_place/models/landlord_post_query.dart';
import 'package:dwell/features/my_place/models/neighbor_post.dart';
import 'package:dwell/features/my_place/providers/my_place_providers.dart';

/// 화면이 붙기 전에 데이터 모양만 검증한다
void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('place summary carries the building address and its signals', () async {
    final place = await container.read(placeSummaryProvider.future);

    expect(place.address, startsWith('245 W 107th St'));
    expect(place.risingIssues, isNotEmpty);
  });

  test('signal detail only collects posts tagged for that issue', () async {
    final detail = await container.read(signalDetailProvider(103).future);

    expect(detail, isNotNull);
    expect(detail!.insight, isNotNull);
    expect(detail.posts, isNotEmpty);
    for (final post in detail.posts) {
      expect(
        post.tags.any(
          (tag) =>
              tag == '#ceilingleak' || tag == '#waterleak' || tag == '#tempfix',
        ),
        isTrue,
        reason: 'unrelated post ${post.postId}',
      );
    }
  });

  test('inspection guide keeps symptom keys for the server', () async {
    final guide = await container.read(inspectionGuideProvider(102).future);

    expect(guide, isNotNull);
    expect(guide!.symptoms, hasLength(4));
    expect(guide.symptoms.first.key, 'ROACHES_SEEN');
    expect(guide.symptoms.first.label.native, isNotNull);
  });

  test('tenant summary counts come from the posts themselves', () async {
    final posts = container.read(landlordPostsProvider);
    final summary = await container.read(landlordPostSummaryProvider.future);

    expect(summary.postCount, posts.length);
    expect(summary.previewPosts, hasLength(3));

    var counted = 0;
    for (final topic in PostTopic.values) {
      counted += summary.countOf(topic);
    }
    expect(counted, posts.length, reason: 'tile numbers must add up');
  });

  test('landlord post query filters, sorts and pages', () async {
    const query = LandlordPostQuery(topics: {PostTopic.slowRepairs}, size: 3);

    final first = await container.read(landlordPostPageProvider(query).future);

    expect(first.content, hasLength(3));
    expect(first.hasNext, isTrue);
    expect(
      first.content.every((p) => p.landlordTopic == PostTopic.slowRepairs),
      isTrue,
    );
    expect(
      first.content.first.createdAt.isAfter(first.content.last.createdAt),
      isTrue,
      reason: 'newest first by default',
    );

    final second = await container.read(
      landlordPostPageProvider(query.copyWith(page: 1)).future,
    );
    expect(second.totalElements, first.totalElements);
    expect(second.content.length, first.totalElements - 3);
    expect(second.hasNext, isFalse);
  });

  test('searching matches title and body', () async {
    const query = LandlordPostQuery(query: 'plumber');
    final page = await container.read(landlordPostPageProvider(query).future);

    expect(page.totalElements, greaterThan(0));
    expect(page.content.first.title, contains('plumber'));
  });
}
