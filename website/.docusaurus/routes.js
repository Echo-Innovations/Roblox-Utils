import React from 'react';
import ComponentCreator from '@docusaurus/ComponentCreator';

export default [
  {
    path: '/Roblox-Utils/blog',
    component: ComponentCreator('/Roblox-Utils/blog', '95f'),
    exact: true
  },
  {
    path: '/Roblox-Utils/docs',
    component: ComponentCreator('/Roblox-Utils/docs', 'b28'),
    routes: [
      {
        path: '/Roblox-Utils/docs',
        component: ComponentCreator('/Roblox-Utils/docs', '910'),
        routes: [
          {
            path: '/Roblox-Utils/docs',
            component: ComponentCreator('/Roblox-Utils/docs', '701'),
            routes: [
              {
                path: '/Roblox-Utils/docs/API/color',
                component: ComponentCreator('/Roblox-Utils/docs/API/color', 'bb9'),
                exact: true,
                sidebar: "docs"
              },
              {
                path: '/Roblox-Utils/docs/API/functions',
                component: ComponentCreator('/Roblox-Utils/docs/API/functions', '0c2'),
                exact: true,
                sidebar: "docs"
              },
              {
                path: '/Roblox-Utils/docs/API/instances',
                component: ComponentCreator('/Roblox-Utils/docs/API/instances', '2a5'),
                exact: true,
                sidebar: "docs"
              },
              {
                path: '/Roblox-Utils/docs/API/math-randomness',
                component: ComponentCreator('/Roblox-Utils/docs/API/math-randomness', '895'),
                exact: true,
                sidebar: "docs"
              },
              {
                path: '/Roblox-Utils/docs/API/signals',
                component: ComponentCreator('/Roblox-Utils/docs/API/signals', '644'),
                exact: true,
                sidebar: "docs"
              },
              {
                path: '/Roblox-Utils/docs/API/strings',
                component: ComponentCreator('/Roblox-Utils/docs/API/strings', 'b05'),
                exact: true,
                sidebar: "docs"
              },
              {
                path: '/Roblox-Utils/docs/API/tables',
                component: ComponentCreator('/Roblox-Utils/docs/API/tables', '032'),
                exact: true,
                sidebar: "docs"
              },
              {
                path: '/Roblox-Utils/docs/API/time',
                component: ComponentCreator('/Roblox-Utils/docs/API/time', 'f27'),
                exact: true,
                sidebar: "docs"
              },
              {
                path: '/Roblox-Utils/docs/API/ui',
                component: ComponentCreator('/Roblox-Utils/docs/API/ui', '150'),
                exact: true,
                sidebar: "docs"
              },
              {
                path: '/Roblox-Utils/docs/API/value',
                component: ComponentCreator('/Roblox-Utils/docs/API/value', '173'),
                exact: true,
                sidebar: "docs"
              },
              {
                path: '/Roblox-Utils/docs/getting-started',
                component: ComponentCreator('/Roblox-Utils/docs/getting-started', '428'),
                exact: true,
                sidebar: "docs"
              },
              {
                path: '/Roblox-Utils/docs/installation',
                component: ComponentCreator('/Roblox-Utils/docs/installation', '583'),
                exact: true,
                sidebar: "docs"
              },
              {
                path: '/Roblox-Utils/docs/introduction',
                component: ComponentCreator('/Roblox-Utils/docs/introduction', '183'),
                exact: true,
                sidebar: "docs"
              }
            ]
          }
        ]
      }
    ]
  },
  {
    path: '/Roblox-Utils/',
    component: ComponentCreator('/Roblox-Utils/', 'ccb'),
    exact: true
  },
  {
    path: '*',
    component: ComponentCreator('*'),
  },
];
