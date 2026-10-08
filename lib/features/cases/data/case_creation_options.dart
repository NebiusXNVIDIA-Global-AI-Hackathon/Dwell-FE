import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

abstract final class CaseCreationOptions {
  static const Map<String, String> issueTypes = {
    'Heat & Hot Water': 'assets/icons/issues/heat.svg',
    'Water & Flooding': 'assets/icons/issues/water.svg',
    'Plumbing': 'assets/icons/issues/plumbing.svg',
    'Mold & Moisture': 'assets/icons/issues/mold.svg',
    'Pests': 'assets/icons/issues/pests.svg',
    'Electricity': 'assets/icons/issues/electricity.svg',
    'Gas': 'assets/icons/issues/gas.svg',
    'Appliances': 'assets/icons/issues/appliances.svg',
    'Ventilation': 'assets/icons/issues/ventilation.svg',
    'Safety': 'assets/icons/issues/safety.svg',
  };
  static const Map<String, List<String>> specificIssues = {
    'Heat & Hot Water': [
      'No Heat',
      'Not Enough Heat',
      'No Hot Water',
      'Water Not Hot Enough',
      "Heat Won't Turn Off",
      'Radiator Issue',
      'Other',
    ],
    'Water & Flooding': [
      'Water Leak',
      'Water Stain or Damage',
      'Active Dripping',
      'Flooding',
      'Water on Floor',
      'Other',
    ],
    'Plumbing': [
      'Clogged Drain',
      'Toilet Issue',
      'Sink Issue',
      'Low Water Pressure',
      'Pipe Issue',
      'Faucet Issue',
      'Sewage Backup',
      'Other',
    ],
    'Mold & Moisture': [
      'Visible Mold',
      'Damp Wall or Ceiling',
      'Musty Smell',
      'Condensation',
      'Recurring Moisture',
      'Peeling Paint',
      'Other',
    ],
    'Pests': [
      'Roaches',
      'Mice / Rats',
      'Bed Bugs',
      'Ants',
      'Flies / Gnats',
      'Other Insects',
      'Other',
    ],
    'Electricity': [
      'No Power',
      'Outlet Not Working',
      'Light / Fixture Issue',
      'Flickering Lights',
      'Breaker Keeps Tripping',
      'Exposed Wiring',
      'Sparks / Burning Smell',
      'Other',
    ],
    'Gas': [
      'Gas Smell',
      'Suspected Gas Leak',
      'Gas Shut Off',
      'Gas Appliance Issue',
      'Gas Line / Pipe Issue',
      'Other',
    ],
    'Appliances': [
      'Refrigerator',
      'Stove / Oven',
      'Dishwasher',
      'Washer',
      'Dryer',
      'Microwave',
      'Other Appliance',
    ],
    'Ventilation': [
      'Vent Not Working',
      'Weak Airflow',
      'Exhaust Fan Issue',
      'Blocked Vent',
      'Excessive Humidity',
      'Bad Odor / Poor Airflow',
      'Other',
    ],
    'Safety': [
      'Broken Lock',
      "Door Won't Secure",
      "Window Won't Lock",
      'Smoke Detector Issue',
      'Carbon Monoxide Detector',
      'Broken / Unsafe Stairs',
      'Loose Railing',
      'Other',
    ],
  };
  // 3단계: 문제 발생 위치
  static const Map<String, IconData> locations = {
    'Bathroom': LucideIcons.bath,
    'Kitchen': LucideIcons.cookingPot,
    'Living Room': LucideIcons.house,
    'Bedroom': LucideIcons.bedDouble,
    'Laundry Area': LucideIcons.towelRack,
    'Balcony': LucideIcons.fence,
    'Entire Unit': LucideIcons.mapPinHouse,
    'Exterior': LucideIcons.building2,
    'Other': LucideIcons.messageSquareMore,
  };

  static bool requiresOtherInput(String? issue) {
    return issue == 'Other' || issue == 'Other Appliance';
  }

  // Other 위치는 직접 입력 필요
  static bool requiresOtherLocationInput(String? location) {
    return location == 'Other';
  }

  // Entire Unit은 부위 선택 단계 생략
  static bool skipsAffectedArea(String? location) {
    return location == 'Entire Unit';
  }
}
