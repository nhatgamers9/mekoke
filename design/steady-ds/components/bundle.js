/* @ds-bundle: {"format":4,"namespace":"Steady","components":[{"name":"Icon"},{"name":"Button"},{"name":"IconButton"},{"name":"Chip"},{"name":"SegmentedControl"},{"name":"Switch"},{"name":"ListRow"},{"name":"TimerRing"},{"name":"ProgressBar"},{"name":"SoundTile"},{"name":"StreakCard"},{"name":"MoodPicker"},{"name":"PlanOption"},{"name":"TabBar"},{"name":"IconTile"},{"name":"FilterChips"},{"name":"Stepper"},{"name":"Slider"},{"name":"OptionCard"},{"name":"Keypad"},{"name":"TransactionRow"},{"name":"BudgetRow"}]} */
(function () {
  var React = window.React, h = React.createElement;
  var ICONS = {"audio-waveform":[["path",{"d":"M2 13a2 2 0 0 0 2-2V7a2 2 0 0 1 4 0v13a2 2 0 0 0 4 0V4a2 2 0 0 1 4 0v13a2 2 0 0 0 4 0v-4a2 2 0 0 1 2-2"}]],"timer":[["line",{"x1":"10","x2":"14","y1":"2","y2":"2"}],["line",{"x1":"12","x2":"15","y1":"14","y2":"11"}],["circle",{"cx":"12","cy":"14","r":"8"}]],"sprout":[["path",{"d":"M14 9.536V7a4 4 0 0 1 4-4h1.5a.5.5 0 0 1 .5.5V5a4 4 0 0 1-4 4 4 4 0 0 0-4 4c0 2 1 3 1 5a5 5 0 0 1-1 3"}],["path",{"d":"M4 9a5 5 0 0 1 8 4 5 5 0 0 1-8-4"}],["path",{"d":"M5 21h14"}]],"notebook-pen":[["path",{"d":"M13.4 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-7.4"}],["path",{"d":"M2 6h4"}],["path",{"d":"M2 10h4"}],["path",{"d":"M2 14h4"}],["path",{"d":"M2 18h4"}],["path",{"d":"M21.378 5.626a1 1 0 1 0-3.004-3.004l-5.01 5.012a2 2 0 0 0-.506.854l-.837 2.87a.5.5 0 0 0 .62.62l2.87-.837a2 2 0 0 0 .854-.506z"}]],"play":[["path",{"d":"M5 5a2 2 0 0 1 3.008-1.728l11.997 6.998a2 2 0 0 1 .003 3.458l-12 7A2 2 0 0 1 5 19z"}]],"pause":[["rect",{"x":"14","y":"3","width":"5","height":"18","rx":"1"}],["rect",{"x":"5","y":"3","width":"5","height":"18","rx":"1"}]],"rotate-ccw":[["path",{"d":"M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"}],["path",{"d":"M3 3v5h5"}]],"plus":[["path",{"d":"M5 12h14"}],["path",{"d":"M12 5v14"}]],"minus":[["path",{"d":"M5 12h14"}]],"check":[["path",{"d":"M20 6 9 17l-5-5"}]],"x":[["path",{"d":"M18 6 6 18"}],["path",{"d":"m6 6 12 12"}]],"chevron-right":[["path",{"d":"m9 18 6-6-6-6"}]],"settings":[["path",{"d":"M9.671 4.136a2.34 2.34 0 0 1 4.659 0 2.34 2.34 0 0 0 3.319 1.915 2.34 2.34 0 0 1 2.33 4.033 2.34 2.34 0 0 0 0 3.831 2.34 2.34 0 0 1-2.33 4.033 2.34 2.34 0 0 0-3.319 1.915 2.34 2.34 0 0 1-4.659 0 2.34 2.34 0 0 0-3.32-1.915 2.34 2.34 0 0 1-2.33-4.033 2.34 2.34 0 0 0 0-3.831A2.34 2.34 0 0 1 6.35 6.051a2.34 2.34 0 0 0 3.319-1.915"}],["circle",{"cx":"12","cy":"12","r":"3"}]],"lock":[["rect",{"width":"18","height":"11","x":"3","y":"11","rx":"2","ry":"2"}],["path",{"d":"M7 11V7a5 5 0 0 1 10 0v4"}]],"bell":[["path",{"d":"M10.268 21a2 2 0 0 0 3.464 0"}],["path",{"d":"M3.262 15.326A1 1 0 0 0 4 17h16a1 1 0 0 0 .74-1.673C19.41 13.956 18 12.499 18 8A6 6 0 0 0 6 8c0 4.499-1.411 5.956-2.738 7.326"}]],"cloud-rain":[["path",{"d":"M4 14.899A7 7 0 1 1 15.71 8h1.79a4.5 4.5 0 0 1 2.5 8.242"}],["path",{"d":"M16 14v6"}],["path",{"d":"M8 14v6"}],["path",{"d":"M12 16v6"}]],"waves":[["path",{"d":"M2 12q2.5 2 5 0t5 0 5 0 5 0"}],["path",{"d":"M2 19q2.5 2 5 0t5 0 5 0 5 0"}],["path",{"d":"M2 5q2.5 2 5 0t5 0 5 0 5 0"}]],"wind":[["path",{"d":"M12.8 19.6A2 2 0 1 0 14 16H2"}],["path",{"d":"M17.5 8a2.5 2.5 0 1 1 2 4H2"}],["path",{"d":"M9.8 4.4A2 2 0 1 1 11 8H2"}]],"leaf":[["path",{"d":"M11 20a10 10 0 0010-10 25.9 25.9 0 00-1.04-7.281 1 1 0 00-1.755-.325C15.833 5.5 13 5.5 9.8 6.1A7 7 0 0011 20"}],["path",{"d":"M2 21a5 5 0 012.911-4.544C7.613 15.212 8.351 15.24 11 13"}]],"moon":[["path",{"d":"M20.985 12.486a9 9 0 1 1-9.473-9.472c.405-.022.617.46.402.803a6 6 0 0 0 8.268 8.268c.344-.215.825-.004.803.401"}]],"utensils":[["path",{"d":"M3 2v7c0 1.1.9 2 2 2h4a2 2 0 0 0 2-2V2"}],["path",{"d":"M7 2v20"}],["path",{"d":"M21 15V2a5 5 0 0 0-5 5v6c0 1.1.9 2 2 2h3Zm0 0v7"}]],"dumbbell":[["path",{"d":"M17.596 12.768a2 2 0 1 0 2.829-2.829l-1.768-1.767a2 2 0 0 0 2.828-2.829l-2.828-2.828a2 2 0 0 0-2.829 2.828l-1.767-1.768a2 2 0 1 0-2.829 2.829z"}],["path",{"d":"m2.5 21.5 1.4-1.4"}],["path",{"d":"m20.1 3.9 1.4-1.4"}],["path",{"d":"M5.343 21.485a2 2 0 1 0 2.829-2.828l1.767 1.768a2 2 0 1 0 2.829-2.829l-6.364-6.364a2 2 0 1 0-2.829 2.829l1.768 1.767a2 2 0 0 0-2.828 2.829z"}],["path",{"d":"m9.6 14.4 4.8-4.8"}]],"volume-2":[["path",{"d":"M11 4.702a.705.705 0 0 0-1.203-.498L6.413 7.587A1.4 1.4 0 0 1 5.416 8H3a1 1 0 0 0-1 1v6a1 1 0 0 0 1 1h2.416a1.4 1.4 0 0 1 .997.413l3.383 3.384A.705.705 0 0 0 11 19.298z"}],["path",{"d":"M16 9a5 5 0 0 1 0 6"}],["path",{"d":"M19.364 18.364a9 9 0 0 0 0-12.728"}]],"skip-forward":[["path",{"d":"M21 4v16"}],["path",{"d":"M6.029 4.285A2 2 0 0 0 3 6v12a2 2 0 0 0 3.029 1.715l9.997-5.998a2 2 0 0 0 .003-3.432z"}]],"cloud-drizzle":[["path",{"d":"M4 14.899A7 7 0 1 1 15.71 8h1.79a4.5 4.5 0 0 1 2.5 8.242"}],["path",{"d":"M8 19v1"}],["path",{"d":"M8 14v1"}],["path",{"d":"M16 19v1"}],["path",{"d":"M16 14v1"}],["path",{"d":"M12 21v1"}],["path",{"d":"M12 16v1"}]],"cloud-lightning":[["path",{"d":"M6 16.326A7 7 0 1 1 15.71 8h1.79a4.5 4.5 0 0 1 .5 8.973"}],["path",{"d":"m13 12-3 5h4l-3 5"}]],"umbrella":[["path",{"d":"M12 13v7a2 2 0 0 0 4 0"}],["path",{"d":"M12 2v2"}],["path",{"d":"M20.992 13a1 1 0 0 0 .97-1.274 10.284 10.284 0 0 0-19.923 0A1 1 0 0 0 3 13z"}]],"shell":[["path",{"d":"M14 11a2 2 0 1 1-4 0 4 4 0 0 1 8 0 6 6 0 0 1-12 0 8 8 0 0 1 16 0 10 10 0 1 1-20 0 11.93 11.93 0 0 1 2.42-7.22 2 2 0 1 1 3.16 2.44"}]],"trees":[["path",{"d":"M10 10v.2A3 3 0 0 1 8.9 16H5a3 3 0 0 1-1-5.8V10a3 3 0 0 1 6 0Z"}],["path",{"d":"M7 16v6"}],["path",{"d":"M13 19v3"}],["path",{"d":"M12 19h8.3a1 1 0 0 0 .7-1.7L18 14h.3a1 1 0 0 0 .7-1.7L16 9h.2a1 1 0 0 0 .8-1.7L13 3l-1.4 1.5"}]],"flame":[["path",{"d":"M12 3q1 4 4 6.5t3 5.5a1 1 0 0 1-14 0 5 5 0 0 1 1-3 1 1 0 0 0 5 0c0-2-1.5-3-1.5-5q0-2 2.5-4"}]],"droplets":[["path",{"d":"M7 16.3c2.2 0 4-1.83 4-4.05 0-1.16-.57-2.26-1.71-3.19S7.29 6.75 7 5.3c-.29 1.45-1.14 2.84-2.29 3.76S3 11.1 3 12.25c0 2.22 1.8 4.05 4 4.05z"}],["path",{"d":"M12.56 6.6A10.97 10.97 0 0 0 14 3.02c.5 2.5 2 4.9 4 6.5s3 3.5 3 5.5a6.98 6.98 0 0 1-11.91 4.97"}]],"bird":[["path",{"d":"M16 7h.01"}],["path",{"d":"M3.4 18H12a8 8 0 0 0 8-8V7a4 4 0 0 0-7.28-2.3L2 20"}],["path",{"d":"m20 7 2 .5-2 .5"}],["path",{"d":"M10 18v3"}],["path",{"d":"M14 17.75V21"}],["path",{"d":"M7 18a6 6 0 0 0 3.84-10.61"}]],"coffee":[["path",{"d":"M10 2v2"}],["path",{"d":"M14 2v2"}],["path",{"d":"M16 8a1 1 0 0 1 1 1v8a4 4 0 0 1-4 4H7a4 4 0 0 1-4-4V9a1 1 0 0 1 1-1h14a4 4 0 1 1 0 8h-1"}],["path",{"d":"M6 2v2"}]],"train-front":[["path",{"d":"M8 3.1V7a4 4 0 0 0 8 0V3.1"}],["path",{"d":"m9 15-1-1"}],["path",{"d":"m15 15 1-1"}],["path",{"d":"M9 19c-2.8 0-5-2.2-5-5v-4a8 8 0 0 1 16 0v4c0 2.8-2.2 5-5 5Z"}],["path",{"d":"m8 19-2 3"}],["path",{"d":"m16 19 2 3"}]],"fan":[["path",{"d":"M10.827 16.379a6.082 6.082 0 0 1-8.618-7.002l5.412 1.45a6.082 6.082 0 0 1 7.002-8.618l-1.45 5.412a6.082 6.082 0 0 1 8.618 7.002l-5.412-1.45a6.082 6.082 0 0 1-7.002 8.618l1.45-5.412Z"}],["path",{"d":"M12 12v.01"}]],"car":[["path",{"d":"M19 17h2c.6 0 1-.4 1-1v-3c0-.9-.7-1.7-1.5-1.9C18.7 10.6 16 10 16 10s-1.3-1.4-2.2-2.3c-.5-.4-1.1-.7-1.8-.7H5c-.6 0-1.1.4-1.4.9l-1.4 2.9A3.7 3.7 0 0 0 2 12v4c0 .6.4 1 1 1h2"}],["circle",{"cx":"7","cy":"17","r":"2"}],["path",{"d":"M9 17h6"}],["circle",{"cx":"17","cy":"17","r":"2"}]],"music":[["path",{"d":"M9 18V5l12-2v13"}],["circle",{"cx":"6","cy":"18","r":"3"}],["circle",{"cx":"18","cy":"16","r":"3"}]],"sliders-horizontal":[["path",{"d":"M10 5H3"}],["path",{"d":"M12 19H3"}],["path",{"d":"M14 3v4"}],["path",{"d":"M16 17v4"}],["path",{"d":"M21 12h-9"}],["path",{"d":"M21 19h-5"}],["path",{"d":"M21 5h-7"}],["path",{"d":"M8 10v4"}],["path",{"d":"M8 12H3"}]],"lock-open":[["rect",{"width":"18","height":"11","x":"3","y":"11","rx":"2","ry":"2"}],["path",{"d":"M7 11V7a5 5 0 0 1 9.9-1"}]],"calendar-check":[["path",{"d":"M8 2v3"}],["path",{"d":"M16 2v3"}],["rect",{"x":"3","y":"3","width":"18","height":"18","rx":"2"}],["path",{"d":"M3 9h18"}],["path",{"d":"m9 15 2 2 4-4"}]],"hourglass":[["path",{"d":"M5 22h14"}],["path",{"d":"M5 2h14"}],["path",{"d":"M17 22v-4.172a2 2 0 0 0-.586-1.414L12 12l-4.414 4.414A2 2 0 0 0 7 17.828V22"}],["path",{"d":"M7 2v4.172a2 2 0 0 0 .586 1.414L12 12l4.414-4.414A2 2 0 0 0 17 6.172V2"}]],"repeat":[["path",{"d":"m17 2 4 4-4 4"}],["path",{"d":"M3 11v-1a4 4 0 0 1 4-4h14"}],["path",{"d":"m7 22-4-4 4-4"}],["path",{"d":"M21 13v1a4 4 0 0 1-4 4H3"}]],"layers":[["path",{"d":"M12.83 2.18a2 2 0 0 0-1.66 0L2.6 6.08a1 1 0 0 0 0 1.83l8.58 3.91a2 2 0 0 0 1.66 0l8.58-3.9a1 1 0 0 0 0-1.83z"}],["path",{"d":"M2 12a1 1 0 0 0 .58.91l8.6 3.91a2 2 0 0 0 1.65 0l8.58-3.9A1 1 0 0 0 22 12"}],["path",{"d":"M2 17a1 1 0 0 0 .58.91l8.6 3.91a2 2 0 0 0 1.65 0l8.58-3.9A1 1 0 0 0 22 17"}]],"armchair":[["path",{"d":"M19 9V6a2 2 0 0 0-2-2H7a2 2 0 0 0-2 2v3"}],["path",{"d":"M3 16a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-5a2 2 0 0 0-4 0v1.5a.5.5 0 0 1-.5.5h-9a.5.5 0 0 1-.5-.5V11a2 2 0 0 0-4 0z"}],["path",{"d":"M5 18v2"}],["path",{"d":"M19 18v2"}]],"bell-ring":[["path",{"d":"M10.268 21a2 2 0 0 0 3.464 0"}],["path",{"d":"M22 8c0-2.3-.8-4.3-2-6"}],["path",{"d":"M3.262 15.326A1 1 0 0 0 4 17h16a1 1 0 0 0 .74-1.673C19.41 13.956 18 12.499 18 8A6 6 0 0 0 6 8c0 4.499-1.411 5.956-2.738 7.326"}],["path",{"d":"M4 2C2.8 3.7 2 5.7 2 8"}]],"wallet":[["path",{"d":"M19 7V4a1 1 0 0 0-1-1H5a2 2 0 0 0 0 4h15a1 1 0 0 1 1 1v4h-3a2 2 0 0 0 0 4h3a1 1 0 0 0 1-1v-2a1 1 0 0 0-1-1"}],["path",{"d":"M3 5v14a2 2 0 0 0 2 2h15a1 1 0 0 0 1-1v-4"}]],"receipt":[["path",{"d":"M12 17V7"}],["path",{"d":"M16 8h-6a2 2 0 0 0 0 4h4a2 2 0 0 1 0 4H8"}],["path",{"d":"M4 3a1 1 0 0 1 1-1 1.3 1.3 0 0 1 .7.2l.933.6a1.3 1.3 0 0 0 1.4 0l.934-.6a1.3 1.3 0 0 1 1.4 0l.933.6a1.3 1.3 0 0 0 1.4 0l.933-.6a1.3 1.3 0 0 1 1.4 0l.934.6a1.3 1.3 0 0 0 1.4 0l.933-.6A1.3 1.3 0 0 1 19 2a1 1 0 0 1 1 1v18a1 1 0 0 1-1 1 1.3 1.3 0 0 1-.7-.2l-.933-.6a1.3 1.3 0 0 0-1.4 0l-.934.6a1.3 1.3 0 0 1-1.4 0l-.933-.6a1.3 1.3 0 0 0-1.4 0l-.933.6a1.3 1.3 0 0 1-1.4 0l-.934-.6a1.3 1.3 0 0 0-1.4 0l-.933.6a1.3 1.3 0 0 1-.7.2 1 1 0 0 1-1-1z"}]],"shopping-cart":[["path",{"d":"m2.05 2.05 1.099-.028a1 1 0 0 1 1.008.815l2.69 14.347A1 1 0 0 0 7.83 18H18"}],["path",{"d":"M4.563 5h16.435a1 1 0 0 1 .981 1.204l-1.026 6.226A2 2 0 0 1 18.962 14H6.25"}],["circle",{"cx":"18","cy":"20","r":"2"}],["circle",{"cx":"8","cy":"20","r":"2"}]],"house":[["path",{"d":"M15 21v-8a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v8"}],["path",{"d":"M3 10a2 2 0 0 1 .709-1.528l7-6a2 2 0 0 1 2.582 0l7 6A2 2 0 0 1 21 10v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"}]],"heart-pulse":[["path",{"d":"M2 9.5a5.5 5.5 0 0 1 9.591-3.676.56.56 0 0 0 .818 0A5.49 5.49 0 0 1 22 9.5c0 2.29-1.5 4-3 5.5l-5.492 5.313a2 2 0 0 1-3 .019L5 15c-1.5-1.5-3-3.2-3-5.5"}],["path",{"d":"M3.22 13H9.5l.5-1 2 4.5 2-7 1.5 3.5h5.27"}]],"gift":[["path",{"d":"M12 7v14"}],["path",{"d":"M20 11v8a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2v-8"}],["path",{"d":"M7.5 7a1 1 0 0 1 0-5A4.8 8 0 0 1 12 7a4.8 8 0 0 1 4.5-5 1 1 0 0 1 0 5"}],["rect",{"x":"3","y":"7","width":"18","height":"4","rx":"1"}]],"piggy-bank":[["path",{"d":"M11 17h3v2a1 1 0 0 0 1 1h2a1 1 0 0 0 1-1v-3a3.16 3.16 0 0 0 2-2h1a1 1 0 0 0 1-1v-2a1 1 0 0 0-1-1h-1a5 5 0 0 0-2-4V3a4 4 0 0 0-3.2 1.6l-.3.4H11a6 6 0 0 0-6 6v1a5 5 0 0 0 2 4v3a1 1 0 0 0 1 1h2a1 1 0 0 0 1-1z"}],["path",{"d":"M16 10h.01"}],["path",{"d":"M2 8v1a2 2 0 0 0 2 2h1"}]],"banknote":[["rect",{"width":"20","height":"12","x":"2","y":"6","rx":"2"}],["circle",{"cx":"12","cy":"12","r":"2"}],["path",{"d":"M6 12h.01M18 12h.01"}]],"credit-card":[["rect",{"width":"20","height":"14","x":"2","y":"5","rx":"2"}],["line",{"x1":"2","x2":"22","y1":"10","y2":"10"}],["path",{"d":"M6 14h2"}]],"arrow-down-left":[["path",{"d":"M17 7 7 17"}],["path",{"d":"M17 17H7V7"}]],"arrow-up-right":[["path",{"d":"M7 7h10v10"}],["path",{"d":"M7 17 17 7"}]],"search":[["path",{"d":"m21 21-4.34-4.34"}],["circle",{"cx":"11","cy":"11","r":"8"}]],"delete":[["path",{"d":"M10 5a2 2 0 0 0-1.344.519l-6.328 5.74a1 1 0 0 0 0 1.481l6.328 5.741A2 2 0 0 0 10 19h10a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2z"}],["path",{"d":"m12 9 6 6"}],["path",{"d":"m18 9-6 6"}]],"shirt":[["path",{"d":"M20.38 3.46 16 2a4 4 0 0 1-8 0L3.62 3.46a2 2 0 0 0-1.34 2.23l.58 3.47a1 1 0 0 0 .99.84H6v10c0 1.1.9 2 2 2h8a2 2 0 0 0 2-2V10h2.15a1 1 0 0 0 .99-.84l.58-3.47a2 2 0 0 0-1.34-2.23z"}]],"plane":[["path",{"d":"M17.8 19.2 16 11l3.5-3.5C21 6 21.5 4 21 3c-1-.5-3 0-4.5 1.5L13 8 4.8 6.2c-.5-.1-.9.1-1.1.5l-.3.5c-.2.5-.1 1 .3 1.3L9 12l-2 3H4l-1 1 3 2 2 3 1-1v-3l3-2 3.5 5.3c.3.4.8.5 1.3.3l.5-.2c.4-.3.6-.7.5-1.2z"}]],"zap":[["path",{"d":"M15.914 4a1.5 1.5 0 00-2.474-1.561l-9 9A1.5 1.5 0 005.5 14h4.002a.5.5 0 01.471.666L8.086 20a1.5 1.5 0 002.475 1.56l9-9A1.5 1.5 0 0018.5 10h-3.997a.5.5 0 01-.472-.667z"}]],"smartphone":[["rect",{"width":"14","height":"20","x":"5","y":"2","rx":"2","ry":"2"}],["path",{"d":"M12 18h.01"}]],"calendar":[["path",{"d":"M8 2v3"}],["path",{"d":"M16 2v3"}],["rect",{"x":"3","y":"3","width":"18","height":"18","rx":"2"}],["path",{"d":"M3 9h18"}]],"triangle-alert":[["path",{"d":"m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3"}],["path",{"d":"M12 9v4"}],["path",{"d":"M12 17h.01"}]],"arrow-left-right":[["path",{"d":"M8 3 4 7l4 4"}],["path",{"d":"M4 7h16"}],["path",{"d":"m16 21 4-4-4-4"}],["path",{"d":"M20 17H4"}]],"briefcase":[["path",{"d":"M16 20V4a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"}],["rect",{"width":"20","height":"14","x":"2","y":"6","rx":"2"}]],"graduation-cap":[["path",{"d":"M21.42 10.922a1 1 0 0 0-.019-1.838L12.83 5.18a2 2 0 0 0-1.66 0L2.6 9.08a1 1 0 0 0 0 1.832l8.57 3.908a2 2 0 0 0 1.66 0z"}],["path",{"d":"M22 10v6"}],["path",{"d":"M6 12.5V16a6 3 0 0 0 12 0v-3.5"}]]};

  function cx() { return Array.prototype.filter.call(arguments, Boolean).join(' '); }
  function omit(p, keys) { var o = {}; for (var k in p) { if (keys.indexOf(k) < 0) o[k] = p[k]; } return o; }
  function clamp01(v) { v = Number(v) || 0; return v < 0 ? 0 : v > 1 ? 1 : v; }

  /** Lucide stroke icon by name; inherits CSS color. */
  function Icon(p) {
    var size = p.size || 24, nodes = ICONS[p.name] || [];
    return h('svg', {
      className: cx('st-icon', p.className), width: size, height: size, viewBox: '0 0 24 24',
      fill: 'none', stroke: 'currentColor', strokeWidth: p.strokeWidth || 2, strokeLinecap: 'round', strokeLinejoin: 'round',
      role: p.label ? 'img' : undefined, 'aria-label': p.label, 'aria-hidden': p.label ? undefined : true, focusable: 'false'
    }, nodes.map(function (n, i) { return h(n[0], Object.assign({ key: i }, n[1])); }));
  }

  /** Pill button. One primary per screen. */
  function Button(p) {
    var variant = p.variant || 'secondary', size = p.size || 'lg';
    var rest = omit(p, ['variant', 'size', 'block', 'icon', 'children', 'className']);
    return h('button', Object.assign({ type: 'button' }, rest, {
      className: cx('st-btn', 'st-btn-' + variant, 'st-btn-' + size, p.block && 'st-btn-block', 'body-strong', p.className)
    }), p.icon ? h(Icon, { name: p.icon, size: 20 }) : null, h('span', null, p.children));
  }

  /** Round icon-only button; label is required (screen readers). */
  function IconButton(p) {
    var variant = p.variant || 'filled';
    var rest = omit(p, ['variant', 'icon', 'label', 'className']);
    var size = variant === 'play' ? 32 : 22;
    return h('button', Object.assign({ type: 'button' }, rest, {
      className: cx('st-ibtn', 'st-ibtn-' + variant, p.className), 'aria-label': p.label, title: p.label
    }), h(Icon, { name: p.icon, size: size, strokeWidth: variant === 'play' ? 2.25 : 2 }));
  }

  /** Short status or plan label. */
  function Chip(p) {
    return h('span', { className: cx('st-chip', 'st-chip-' + (p.tone || 'neutral'), 'label', p.className) },
      p.icon ? h(Icon, { name: p.icon, size: 16 }) : null, h('span', null, p.children));
  }

  /** Two to four mutually exclusive presets (16:8 · 18:6 · 20:4). */
  function SegmentedControl(p) {
    var opts = p.options || [];
    return h('div', { className: cx('st-seg', p.className), role: 'radiogroup', 'aria-label': p.label },
      opts.map(function (o) {
        var on = o.value === p.value;
        return h('button', {
          key: o.value, type: 'button', role: 'radio', 'aria-checked': on,
          className: cx('st-seg-item', 'label', on && 'is-on'),
          onClick: p.onChange ? function () { p.onChange(o.value); } : undefined
        }, o.label);
      }));
  }

  /** On/off setting. */
  function Switch(p) {
    return h('button', {
      type: 'button', role: 'switch', 'aria-checked': !!p.checked, 'aria-label': p.label,
      className: cx('st-switch', p.checked && 'is-on', p.className),
      onClick: p.onChange ? function () { p.onChange(!p.checked); } : undefined
    }, h('span', { className: 'st-switch-knob' }));
  }

  /** Settings / history row: icon, title, detail, trailing. */
  function ListRow(p) {
    var trailing = p.trailing;
    if (trailing === 'chevron') trailing = h(Icon, { name: 'chevron-right', size: 20, className: 'st-row-chev' });
    else if (typeof trailing === 'string') trailing = h('span', { className: 'label st-muted' }, trailing);
    return h(p.onClick ? 'button' : 'div', { type: p.onClick ? 'button' : undefined, className: cx('st-listrow', p.className), onClick: p.onClick },
      p.icon ? h('span', { className: 'st-listrow-icon' }, h(Icon, { name: p.icon, size: 20 })) : null,
      h('span', { className: 'st-listrow-text' },
        h('span', { className: 'body' }, p.title),
        p.detail ? h('span', { className: 'label st-muted' }, p.detail) : null),
      trailing ? h('span', { className: 'st-listrow-trail' }, trailing) : null);
  }

  /** Circular countdown: fasting window, sleep timer, focus session. */
  function TimerRing(p) {
    var size = p.size || 264, stroke = p.stroke || 14, r = (size - stroke) / 2, c = 2 * Math.PI * r;
    var prog = clamp01(p.progress), tone = p.tone || 'amber';
    return h('div', { className: cx('st-ring', 'st-ring-' + tone, p.className), style: { width: size, height: size }, role: 'timer', 'aria-label': (p.phase ? p.phase + ' ' : '') + p.time },
      h('svg', { width: size, height: size, viewBox: '0 0 ' + size + ' ' + size, 'aria-hidden': true },
        h('circle', { className: 'st-ring-track', cx: size / 2, cy: size / 2, r: r, fill: 'none', strokeWidth: stroke }),
        h('circle', { className: 'st-ring-prog', cx: size / 2, cy: size / 2, r: r, fill: 'none', strokeWidth: stroke, strokeLinecap: 'round',
          strokeDasharray: c, strokeDashoffset: c * (1 - prog), transform: 'rotate(-90 ' + size / 2 + ' ' + size / 2 + ')' })),
      h('div', { className: 'st-ring-center' },
        p.phase ? h('span', { className: 'overline st-ring-phase' }, p.phase) : null,
        h('span', { className: cx(p.numerals === 'gym' ? 'count-gym' : 'timer-xl', 'st-tnum') }, p.time),
        p.caption ? h('span', { className: 'label st-muted' }, p.caption) : null));
  }

  /** Linear progress toward a milestone. */
  function ProgressBar(p) {
    var v = clamp01(p.value);
    return h('div', { className: cx('st-bar', 'st-bar-' + (p.tone || 'amber'), p.className), role: 'progressbar', 'aria-valuemin': 0, 'aria-valuemax': 100, 'aria-valuenow': Math.round(v * 100), 'aria-label': p.label },
      h('span', { className: 'st-bar-fill', style: { width: (v * 100) + '%' } }));
  }

  /** One sound in the Focus grid. */
  function SoundTile(p) {
    return h('button', {
      type: 'button', 'aria-pressed': !!p.active, onClick: p.onClick,
      className: cx('st-sound', p.active && 'is-on', p.locked && 'is-locked', p.className)
    },
      h('span', { className: 'st-sound-top' },
        h('span', { className: 'st-sound-icon' }, h(Icon, { name: p.icon, size: 26 })),
        p.locked ? h(Icon, { name: 'lock', size: 16, className: 'st-sound-lock', label: 'Premium' }) : null,
        p.active ? h('span', { className: 'st-eq', 'aria-hidden': true }, h('i'), h('i'), h('i')) : null),
      h('span', { className: 'headline' }, p.name),
      p.detail ? h('span', { className: 'caption st-muted' }, p.detail) : null);
  }

  /** Days-clean counter for one habit. */
  function StreakCard(p) {
    var size = p.size || 'lg', m = p.milestone;
    return h('div', { className: cx('st-streak', 'st-streak-' + size, p.className) },
      h('div', { className: 'st-streak-head' },
        h('span', { className: 'headline' }, p.habit),
        p.since ? h('span', { className: 'label st-muted' }, p.since) : null),
      h('div', { className: 'st-streak-count' },
        h('span', { className: size === 'lg' ? 'count-xl' : 'stat' }, p.days),
        h('span', { className: 'body st-muted' }, p.days === 1 ? 'day' : 'days')),
      m ? h('div', { className: 'st-streak-ms' },
        h(ProgressBar, { value: m.progress, tone: 'tide', label: m.label }),
        h('span', { className: 'caption st-muted' }, m.label)) : null);
  }

  var MOUTHS = ['M8 16.5q4-4 8 0', 'M8.5 16q3.5-2 7 0', 'M8.5 15.5h7', 'M8.5 14.5q3.5 2.5 7 0', 'M7.5 14q4.5 4.5 9 0'];
  var MOODS = ['Awful', 'Low', 'Okay', 'Good', 'Great'];
  function Face(p) {
    return h('svg', { width: 32, height: 32, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 1.75, strokeLinecap: 'round', 'aria-hidden': true },
      h('circle', { cx: 12, cy: 12, r: 9.5 }),
      h('circle', { cx: 9, cy: 10, r: 0.6, fill: 'currentColor' }),
      h('circle', { cx: 15, cy: 10, r: 0.6, fill: 'currentColor' }),
      h('path', { d: MOUTHS[p.level - 1] }));
  }
  /** Five-step mood scale for the nightly check-in. */
  function MoodPicker(p) {
    return h('div', { className: cx('st-mood', p.className), role: 'radiogroup', 'aria-label': p.label || 'How was today?' },
      MOODS.map(function (name, i) {
        var lvl = i + 1, on = p.value === lvl;
        return h('button', { key: lvl, type: 'button', role: 'radio', 'aria-checked': on, className: cx('st-mood-item', on && 'is-on'),
          onClick: p.onChange ? function () { p.onChange(lvl); } : undefined },
          h(Face, { level: lvl }), h('span', { className: 'caption' }, name));
      }));
  }

  /** One subscription plan on the paywall (radio card). */
  function PlanOption(p) {
    return h('button', { type: 'button', role: 'radio', 'aria-checked': !!p.selected, onClick: p.onClick, className: cx('st-plan', p.selected && 'is-on', p.className) },
      h('span', { className: 'st-plan-radio', 'aria-hidden': true }, p.selected ? h(Icon, { name: 'check', size: 16, strokeWidth: 3 }) : null),
      h('span', { className: 'st-plan-text' },
        h('span', { className: 'st-plan-title' }, h('span', { className: 'headline' }, p.title), p.badge ? h(Chip, { tone: 'amber' }, p.badge) : null),
        p.note ? h('span', { className: 'label st-muted' }, p.note) : null),
      h('span', { className: 'st-plan-price' }, h('span', { className: 'body-strong' }, p.price), p.period ? h('span', { className: 'caption st-muted' }, p.period) : null));
  }

  /** Bottom navigation: Focus · Timer · Streaks · Check-in. */
  function TabBar(p) {
    var items = p.items || [];
    return h('nav', { className: cx('st-tabbar', p.className), 'aria-label': 'Main' },
      items.map(function (it, i) {
        var on = i === p.active;
        return h('button', { key: it.label, type: 'button', className: cx('st-tab', on && 'is-on'), 'aria-current': on ? 'page' : undefined,
          onClick: p.onChange ? function () { p.onChange(i); } : undefined },
          h('span', { className: 'st-tab-pill' }, h(Icon, { name: it.icon, size: 22 })),
          h('span', { className: 'caption' }, it.label));
      }));
  }


  /** Compact sound in the 3-column library grid. */
  function IconTile(p) {
    return h('button', {
      type: 'button', 'aria-pressed': !!p.active, onClick: p.onClick,
      className: cx('st-itile', p.active && 'is-on', p.locked && 'is-locked', p.className)
    },
      h('span', { className: 'st-itile-disc' },
        h(Icon, { name: p.icon, size: 26 }),
        p.locked ? h('span', { className: 'st-itile-pro caption' }, 'PRO') : null),
      h('span', { className: 'caption st-itile-name' }, p.name));
  }

  /** Horizontal filter row (sound categories, history ranges). Single choice. */
  function FilterChips(p) {
    var opts = p.options || [];
    return h('div', { className: cx('st-fchips', p.className), role: 'radiogroup', 'aria-label': p.label },
      opts.map(function (o) {
        var on = o.value === p.value;
        return h('button', {
          key: o.value, type: 'button', role: 'radio', 'aria-checked': on,
          className: cx('st-fchip', 'label', on && 'is-on'),
          onClick: p.onChange ? function () { p.onChange(o.value); } : undefined
        }, o.label);
      }));
  }

  /** Number setting with − and + (interval setup, sleep timer length). */
  function Stepper(p) {
    var label = typeof p.label === 'string' ? p.label : '';
    return h('div', { className: cx('st-stepper', p.className) },
      p.icon ? h('span', { className: 'st-listrow-icon' }, h(Icon, { name: p.icon, size: 20 })) : null,
      h('span', { className: 'st-listrow-text' },
        h('span', { className: 'body' }, p.label),
        p.detail ? h('span', { className: 'label st-muted' }, p.detail) : null),
      h('span', { className: 'st-stepper-ctrl' },
        h('button', { type: 'button', className: 'st-stepper-btn', 'aria-label': 'Decrease ' + label, onClick: p.onDecrement, disabled: !!p.atMin }, h(Icon, { name: 'minus', size: 18 })),
        h('span', { className: 'stat st-tnum st-stepper-val', 'aria-live': 'polite' }, p.value),
        h('button', { type: 'button', className: 'st-stepper-btn', 'aria-label': 'Increase ' + label, onClick: p.onIncrement, disabled: !!p.atMax }, h(Icon, { name: 'plus', size: 18 }))));
  }

  /** Volume or level slider (0–1), a real range input. */
  function Slider(p) {
    var v = clamp01(p.value);
    return h('label', { className: cx('st-slider', p.className) },
      p.icon ? h('span', { className: 'st-slider-icon' }, h(Icon, { name: p.icon, size: 20 })) : null,
      h('span', { className: 'st-slider-body' },
        p.title ? h('span', { className: 'st-slider-head' }, h('span', { className: 'body' }, p.title), h('span', { className: 'label st-muted st-tnum' }, Math.round(v * 100) + '%')) : null,
        h('input', { type: 'range', min: 0, max: 100, value: Math.round(v * 100), 'aria-label': p.label || p.title,
          style: { '--st-fill': (v * 100) + '%' },
          onChange: p.onChange ? function (e) { p.onChange(Number(e.target.value) / 100); } : function () {} })));
  }

  /** Selectable card for multi-choice questions (onboarding goals). */
  function OptionCard(p) {
    return h('button', { type: 'button', role: 'checkbox', 'aria-checked': !!p.selected, onClick: p.onClick, className: cx('st-option', p.selected && 'is-on', p.className) },
      p.icon ? h('span', { className: 'st-option-icon' }, h(Icon, { name: p.icon, size: 22 })) : null,
      h('span', { className: 'st-listrow-text' },
        h('span', { className: 'headline' }, p.title),
        p.detail ? h('span', { className: 'label st-muted' }, p.detail) : null),
      h('span', { className: 'st-option-check', 'aria-hidden': true }, p.selected ? h(Icon, { name: 'check', size: 16, strokeWidth: 3 }) : null));
  }


  /** Numeric keypad for entering an amount. */
  var KEYS = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', 'del'];
  function Keypad(p) {
    return h('div', { className: cx('st-keypad', p.className), role: 'group', 'aria-label': p.label || 'Amount keypad' },
      KEYS.map(function (k) {
        var isDel = k === 'del';
        return h('button', { key: k, type: 'button', className: cx('st-key', isDel && 'st-key-del'), 'aria-label': isDel ? 'Delete' : undefined,
          onClick: p.onKey ? function () { p.onKey(k); } : undefined },
          isDel ? h(Icon, { name: 'delete', size: 24 }) : h('span', null, k));
      }));
  }

  /** One income, expense or transfer in a history list. */
  function TransactionRow(p) {
    var kind = p.kind || 'expense';
    return h(p.onClick ? 'button' : 'div', { type: p.onClick ? 'button' : undefined, onClick: p.onClick, className: cx('st-listrow', 'st-txn', 'st-txn-' + kind, p.className) },
      h('span', { className: 'st-listrow-icon' }, h(Icon, { name: p.icon || 'receipt', size: 20 })),
      h('span', { className: 'st-listrow-text' },
        h('span', { className: 'body' }, p.title),
        p.detail ? h('span', { className: 'label st-muted' }, p.detail) : null),
      h('span', { className: 'body-strong st-tnum st-txn-amount' }, p.amount));
  }

  /** One envelope or 50/30/20 bucket: spent against its limit. */
  function BudgetRow(p) {
    var v = clamp01(p.value), over = !!p.over;
    return h('div', { className: cx('st-budget', over && 'is-over', p.className) },
      h('div', { className: 'st-budget-head' },
        p.icon ? h('span', { className: 'st-listrow-icon' }, h(Icon, { name: p.icon, size: 20 })) : null,
        h('span', { className: 'st-listrow-text' },
          h('span', { className: 'body-strong' }, p.name),
          h('span', { className: 'label st-muted st-tnum' }, p.spent + ' of ' + p.limit)),
        h('span', { className: 'st-budget-left label st-tnum' },
          over ? h(Icon, { name: 'triangle-alert', size: 16 }) : null,
          h('span', null, p.left))),
      h('div', { className: 'st-bar st-budget-bar', role: 'progressbar', 'aria-valuemin': 0, 'aria-valuemax': 100, 'aria-valuenow': Math.round(v * 100), 'aria-label': p.name + ' spent' },
        h('span', { className: 'st-bar-fill', style: { width: (over ? 100 : v * 100) + '%' } })));
  }

  var api = { Icon: Icon, Button: Button, IconButton: IconButton, Chip: Chip, SegmentedControl: SegmentedControl, Switch: Switch, ListRow: ListRow,
    TimerRing: TimerRing, ProgressBar: ProgressBar, SoundTile: SoundTile, StreakCard: StreakCard, MoodPicker: MoodPicker, PlanOption: PlanOption, TabBar: TabBar,
    IconTile: IconTile, FilterChips: FilterChips, Stepper: Stepper, Slider: Slider, OptionCard: OptionCard,
    Keypad: Keypad, TransactionRow: TransactionRow, BudgetRow: BudgetRow,
    iconNames: Object.keys(ICONS) };
  window.Steady = Object.assign(window.Steady || {}, api);
})();
