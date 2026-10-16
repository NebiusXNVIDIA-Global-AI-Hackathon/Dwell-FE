// Rising Issue 카드 · 시그널 상세 · Check My Unit

import '../models/building_issue.dart';

const mockBuildingIssues = <BuildingIssue>[
  BuildingIssue(
    id: 'heat',
    title: 'Heating system not working',
    issueType: 'No heat',
    reportCount: 2,
    deaverInsight:
        'Reports come from different lines but all started after Oct 1 — '
        'this may be a central boiler issue. Check your radiators in the morning.',
    checkItems: [
      'Radiator stays cold all day',
      'Radiator is warm only at the bottom',
      'Hot water runs out within a few minutes',
      'Rooms stay below 68°F during the day',
    ],
    postTags: ['noheat', 'radiator', 'boiler'],
  ),
  BuildingIssue(
    id: 'water-leak',
    title: 'Water leak spreading on upper floors',
    issueType: 'Water leak',
    reportCount: 4,
    deaverInsight:
        'Four units on the same line reported a ceiling drip within two weeks — '
        'this may be a riser pipe, not a problem in your unit. Photograph the stain before it dries.',
    checkItems: [
      'Water stain or bubbling paint on the ceiling',
      'Drip that comes back after it dries',
      'Damp smell in the bathroom',
      'Stain is growing week to week',
    ],
    postTags: ['ceilingleak', 'waterleak', 'tempfix'],
  ),
  BuildingIssue(
    id: 'pests',
    title: 'Roaches reported in several units',
    issueType: 'Pests',
    reportCount: 3,
    deaverInsight:
        'Reports cluster around the kitchen stacks on three floors — '
        'this may travel through shared pipes. Sealing food helps, but the building needs treatment.',
    checkItems: [
      'Roaches seen in the kitchen or bathroom',
      'Small dark droppings near sinks',
      'Egg cases in cabinet corners',
      'Roaches coming out during the day',
    ],
    postTags: ['roaches', 'pests'],
  ),
];
