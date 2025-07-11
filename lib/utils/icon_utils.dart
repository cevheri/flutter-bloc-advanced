import 'package:flutter/material.dart';

/// Returns an [IconData] for a given icon name string.
/// If the icon name is not recognized, returns [Icons.help_outline] as default.
IconData getIconFromString(String iconName) {
  switch (iconName.toLowerCase()) {
    case 'home':
      return Icons.home;
    case 'account-tie':
      return Icons.account_circle;
    case 'account-edit-outline':
      return Icons.edit;
    case 'cog-outline':
      return Icons.settings;
    case 'logout':
      return Icons.logout;
    case 'login':
      return Icons.login;
    case 'settings':
      return Icons.settings;
    case 'user':
      return Icons.person;
    case 'customer':
      return Icons.people;
    case 'task':
      return Icons.task;
    case 'dashboard':
      return Icons.dashboard;
    case 'reports':
      return Icons.assessment;
    case 'analytics':
      return Icons.analytics;
    case 'notifications':
      return Icons.notifications;
    case 'help':
      return Icons.help;
    case 'info':
      return Icons.info;
    case 'warning':
      return Icons.warning;
    case 'error':
      return Icons.error;
    case 'success':
      return Icons.check_circle;
    case 'add':
      return Icons.add;
    case 'edit':
      return Icons.edit;
    case 'delete':
      return Icons.delete;
    case 'search':
      return Icons.search;
    case 'filter':
      return Icons.filter_list;
    case 'sort':
      return Icons.sort;
    case 'refresh':
      return Icons.refresh;
    case 'download':
      return Icons.download;
    case 'upload':
      return Icons.upload;
    case 'print':
      return Icons.print;
    case 'share':
      return Icons.share;
    case 'favorite':
      return Icons.favorite;
    case 'bookmark':
      return Icons.bookmark;
    case 'calendar':
      return Icons.calendar_today;
    case 'clock':
      return Icons.access_time;
    case 'location':
      return Icons.location_on;
    case 'phone':
      return Icons.phone;
    case 'email':
      return Icons.email;
    case 'web':
      return Icons.web;
    case 'link':
      return Icons.link;
    case 'attachment':
      return Icons.attach_file;
    case 'image':
      return Icons.image;
    case 'video':
      return Icons.video_library;
    case 'audio':
      return Icons.audiotrack;
    case 'file':
      return Icons.insert_drive_file;
    case 'folder':
      return Icons.folder;
    case 'archive':
      return Icons.archive;
    case 'lock':
      return Icons.lock;
    case 'unlock':
      return Icons.lock_open;
    case 'visibility':
      return Icons.visibility;
    case 'visibility-off':
      return Icons.visibility_off;
    case 'key':
      return Icons.vpn_key;
    case 'security':
      return Icons.security;
    case 'shield':
      return Icons.shield;
    case 'verified':
      return Icons.verified;
    case 'admin':
      return Icons.admin_panel_settings;
    case 'user-management':
      return Icons.people_alt;
    case 'role':
      return Icons.assignment_ind;
    case 'permission':
      return Icons.perm_identity;
    case 'audit':
      return Icons.history;
    case 'log':
      return Icons.list_alt;
    case 'backup':
      return Icons.backup;
    case 'restore':
      return Icons.restore;
    case 'sync':
      return Icons.sync;
    case 'cloud':
      return Icons.cloud;
    case 'database':
      return Icons.storage;
    case 'server':
      return Icons.dns;
    case 'network':
      return Icons.network_check;
    case 'wifi':
      return Icons.wifi;
    case 'bluetooth':
      return Icons.bluetooth;
    case 'gps':
      return Icons.gps_fixed;
    case 'compass':
      return Icons.explore;
    case 'map':
      return Icons.map;
    case 'navigation':
      return Icons.navigation;
    case 'directions':
      return Icons.directions;
    case 'route':
      return Icons.route;
    case 'traffic':
      return Icons.traffic;
    case 'transport':
      return Icons.local_shipping;
    case 'car':
      return Icons.directions_car;
    case 'bike':
      return Icons.directions_bike;
    case 'walk':
      return Icons.directions_walk;
    case 'bus':
      return Icons.directions_bus;
    case 'train':
      return Icons.train;
    case 'plane':
      return Icons.flight;
    case 'boat':
      return Icons.directions_boat;
    case 'subway':
      return Icons.subway;
    case 'tram':
      return Icons.tram;
    case 'taxi':
      return Icons.local_taxi;
    case 'parking':
      return Icons.local_parking;
    case 'gas':
      return Icons.local_gas_station;
    case 'restaurant':
      return Icons.restaurant;
    case 'hotel':
      return Icons.hotel;
    case 'shopping':
      return Icons.shopping_cart;
    case 'store':
      return Icons.store;
    case 'market':
      return Icons.storefront;
    case 'bank':
      return Icons.account_balance;
    case 'atm':
      return Icons.account_balance_wallet;
    case 'payment':
      return Icons.payment;
    case 'credit-card':
      return Icons.credit_card;
    case 'money':
      return Icons.attach_money;
    case 'currency':
      return Icons.currency_exchange;
    case 'exchange':
      return Icons.swap_horiz;
    case 'investment':
      return Icons.trending_up;
    case 'chart':
      return Icons.show_chart;
    case 'graph':
      return Icons.bar_chart;
    case 'statistics':
      return Icons.analytics;
    case 'data':
      return Icons.data_usage;
    case 'table':
      return Icons.table_chart;
    case 'grid':
      return Icons.grid_on;
    case 'list':
      return Icons.list;
    case 'view-list':
      return Icons.view_list;
    case 'view-module':
      return Icons.view_module;
    case 'view-grid':
      return Icons.view_comfy;
    case 'view-headline':
      return Icons.view_headline;
    case 'view-array':
      return Icons.view_array;
    case 'view-column':
      return Icons.view_column;
    case 'view-carousel':
      return Icons.view_carousel;
    case 'view-day':
      return Icons.view_day;
    case 'view-week':
      return Icons.view_week;
    case 'view-agenda':
      return Icons.view_agenda;
    case 'view-timeline':
      return Icons.view_timeline;
    case 'view-quilt':
      return Icons.view_quilt;
    case 'view-sidebar':
      return Icons.view_sidebar;
    case 'view-stream':
      return Icons.view_stream;
    case 'view-dashboard':
      return Icons.dashboard;
    case 'view-dashboard-variant':
      return Icons.dashboard_customize;
    case 'view-dashboard-outline':
      return Icons.dashboard_outlined;
    case 'view-dashboard-variant-outline':
      return Icons.dashboard_customize_outlined;
    default:
      return Icons.help_outline; // Default icon for unknown icon names
  }
} 