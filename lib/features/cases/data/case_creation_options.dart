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
  // 4단계: 위치별 부위 이름과 아이콘
  static const Map<String, Map<String, String>> affectedAreas = {
    'Bathroom': {
      'Ceiling': 'assets/icons/areas/ceiling.svg',
      'Wall': 'assets/icons/areas/wall.svg',
      'Floor': 'assets/icons/areas/floor.svg',
      'Shower': 'assets/icons/areas/shower.svg',
      'Sink': 'assets/icons/areas/sink.svg',
      'Toilet': 'assets/icons/areas/toilet.svg',
      'Window Area': 'assets/icons/areas/window.svg',
      'Door Area': 'assets/icons/areas/door.svg',
      'Under Sink': 'assets/icons/areas/under_sink.svg',
      'Ventilation': 'assets/icons/areas/ventilation.svg',
      'Other': 'assets/icons/areas/other.svg',
    },
    'Kitchen': {
      'Ceiling': 'assets/icons/areas/ceiling.svg',
      'Wall': 'assets/icons/areas/wall.svg',
      'Floor': 'assets/icons/areas/floor.svg',
      'Sink': 'assets/icons/areas/kitchen_sink.svg',
      'Under Sink': 'assets/icons/areas/kitchen_under_sink.svg',
      'Countertop': 'assets/icons/areas/countertop.svg',
      'Cabinet': 'assets/icons/areas/cabinet.svg',
      'Appliance Area': 'assets/icons/areas/appliance.svg',
      'Ventilation': 'assets/icons/areas/kitchen_ventilation.svg',
      'Window Area': 'assets/icons/areas/window.svg',
      'Door Area': 'assets/icons/areas/door.svg',
      'Other': 'assets/icons/areas/other.svg',
    },
    'Living Room': {
      'Ceiling': 'assets/icons/areas/ceiling.svg',
      'Wall': 'assets/icons/areas/wall.svg',
      'Floor': 'assets/icons/areas/wood_floor.svg',
      'Window Area': 'assets/icons/areas/window.svg',
      'Door Area': 'assets/icons/areas/door.svg',
      'Sofa / Seating': 'assets/icons/areas/sofa.svg',
      'Electrical Outlet / Fixture': 'assets/icons/areas/outlet.svg',
      'Light Fixture': 'assets/icons/areas/light.svg',
      'HVAC / Vent': 'assets/icons/areas/vent.svg',
      'Fireplace': 'assets/icons/areas/fireplace.svg',
      'Built-in / Shelf': 'assets/icons/areas/shelf.svg',
      'Other': 'assets/icons/areas/other.svg',
    },
    'Bedroom': {
      'Ceiling': 'assets/icons/areas/ceiling.svg',
      'Wall': 'assets/icons/areas/wall.svg',
      'Floor': 'assets/icons/areas/wood_floor.svg',
      'Window Area': 'assets/icons/areas/window.svg',
      'Door Area': 'assets/icons/areas/door.svg',
      'Closet': 'assets/icons/areas/closet.svg',
      'Electrical Outlet / Fixture': 'assets/icons/areas/outlet.svg',
      'Light Fixture': 'assets/icons/areas/light.svg',
      'HVAC / Vent': 'assets/icons/areas/vent.svg',
      'Baseboard': 'assets/icons/areas/baseboard.svg',
      'Built-in / Shelf': 'assets/icons/areas/shelf.svg',
      'Other': 'assets/icons/areas/other.svg',
    },
    'Laundry Area': {
      'Ceiling': 'assets/icons/areas/ceiling.svg',
      'Wall': 'assets/icons/areas/wall.svg',
      'Floor': 'assets/icons/areas/floor.svg',
      'Washer Area': 'assets/icons/areas/washer.svg',
      'Dryer Area': 'assets/icons/areas/dryer.svg',
      'Laundry Sink': 'assets/icons/areas/laundry_sink.svg',
      'Drain': 'assets/icons/areas/drain.svg',
      'Plumbing / Pipe': 'assets/icons/areas/pipe.svg',
      'Ventilation': 'assets/icons/areas/ventilation.svg',
      'Door Area': 'assets/icons/areas/door.svg',
      'Storage / Shelf': 'assets/icons/areas/storage.svg',
      'Other': 'assets/icons/areas/other.svg',
    },
    'Balcony': {
      'Ceiling': 'assets/icons/areas/ceiling.svg',
      'Wall': 'assets/icons/areas/wall.svg',
      'Floor': 'assets/icons/areas/balcony_floor.svg',
      'Railing': 'assets/icons/areas/railing.svg',
      'Door Area': 'assets/icons/areas/balcony_door.svg',
      'Window Area': 'assets/icons/areas/window.svg',
      'Drain': 'assets/icons/areas/drain.svg',
      'Exterior Fixture': 'assets/icons/areas/balcony_light.svg',
      'Outdoor Outlet': 'assets/icons/areas/outdoor_outlet.svg',
      'Planter Area': 'assets/icons/areas/planter.svg',
      'Stairs / Entryway': 'assets/icons/areas/stairs.svg',
      'Other': 'assets/icons/areas/other.svg',
    },
    'Exterior': {
      'Wall': 'assets/icons/areas/exterior_wall.svg',
      'Roof / Overhang': 'assets/icons/areas/roof.svg',
      'Window Area': 'assets/icons/areas/window.svg',
      'Door Area': 'assets/icons/areas/exterior_door.svg',
      'Balcony / Terrace': 'assets/icons/areas/terrace.svg',
      'Drain / Gutter': 'assets/icons/areas/gutter.svg',
      'Exterior Pipe': 'assets/icons/areas/exterior_pipe.svg',
      'Stairs / Entryway': 'assets/icons/areas/stairs.svg',
      'Foundation': 'assets/icons/areas/foundation.svg',
      'Exterior Fixture': 'assets/icons/areas/exterior_light.svg',
      'Walkway / Ground': 'assets/icons/areas/walkway.svg',
      'Other': 'assets/icons/areas/other.svg',
    },

    // 직접 입력한 위치는 우선 공통 부위 목록 사용
    'Other': {
      'Ceiling': 'assets/icons/areas/ceiling.svg',
      'Wall': 'assets/icons/areas/wall.svg',
      'Floor': 'assets/icons/areas/floor.svg',
      'Window Area': 'assets/icons/areas/window.svg',
      'Door Area': 'assets/icons/areas/door.svg',
      'Other': 'assets/icons/areas/other.svg',
    },
  };

  // Other 부위는 직접 입력 필요
  static bool requiresOtherAffectedAreaInput(String? area) {
    return area == 'Other';
  }

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
