## Dashboard design & wireframe

### Widget hierarchy

- `HomeScreen`
  - `AppBar` (existing)
  - `Drawer` (existing)
  - `body: DashboardPage`
    - Header (title + actions)
    - Summary cards row (3 cards: leads/customers/revenue)
    - KPI/Chart placeholder
    - Two-column: Recent activity | Quick actions grid

### Theme

- Use `Theme.of(context).colorScheme` and `textTheme`
- Respect light/dark via existing `AdaptiveTheme`

### Mock data schema (planned)

```
summary: [{id,label,value,trend}]
activities: [{id,title,subtitle,time,type}]
quick_actions: [{id,label,icon}]
```


