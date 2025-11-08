breed [ leaves leaf ]
breed [ dead-leaves dead-leaf ]
breed [ raindrops raindrop ]
breed [ suns sun ]

leaves-own [
  water-level       ;; amount of water in the leaf
  sugar-level       ;; amount of sugar in the leaf
  attachedness      ;; how attached the leaf is to the tree
  chlorophyll       ;; level of chemical making the leaf green
  carotene          ;; level of chemical making the leaf yellow
  anthocyanin       ;; level of chemical making the leaf red
]

raindrops-own [
  location          ;; either "falling", "in root", "in trunk", or "in leaves"
  amount-of-water
]

globals [
  bottom-line       ;; controls where the ground is
  evaporation-temp  ;; temperature at which water evaporates

  ;; <--- ЗМІНА ЛР2 (Варіант): Нові глобальні змінні
  day-duration            ;; Тривалість модельного дня у тіках
  current-sun-intensity   ;; Розрахована інтенсивність сонця
  current-temperature     ;; Розрахована температура
  
  ;; <--- ЗМІНА ЛР2 (Власна): Нова глобальна змінна
  frost-temperature       ;; Температура, при якій починаються заморозки
]

;; ---------------------------------------
;; setup
;; ---------------------------------------

to setup
  clear-all
  set bottom-line min-pycor + 1
  set evaporation-temp 30
  
  ;; <--- ЗМІНА ЛР2 (Варіант + Власна): Ініціалізація нових змінних
  set day-duration 240      ;; Встановлюємо тривалість "дня" (наприклад, 240 тіків)
  set frost-temperature 0   ;; Встановлюємо температуру заморозків
  
  set-default-shape raindrops "circle"
  set-default-shape suns "circle"

  ;; Create sky and grass
  ask patches [
    set pcolor blue - 2
  ]
  ask patches with [ pycor < min-pycor + 2 ] [
    set pcolor green
  ]

  ;; Create leaves
  create-leaves number-of-leaves [
    set chlorophyll 50 + random 50
    set water-level 75 + random 25
    ;; the sugar level is drawn from a normal distribution based on user inputs
    set sugar-level random-normal start-sugar-mean start-sugar-stddev
    set carotene random 100
    change-color
    set attachedness 100 + random 50
    ;; using sqrt in the next command makes the turtles be
    ;; evenly distributed; if we just said "fd random-float 10"
    ;; there'd be more turtles near the center of the tree,
    ;; which would look funny
    fd sqrt random-float 100
  ]

  ;; Create trunk and branches
  ask patches with [
    pxcor = 0 and pycor <= 5 or
    abs pxcor = (pycor + 2) and pycor < 4 or
    abs pxcor = (pycor + 8) and pycor < 3
  ] [
    set pcolor brown
  ]

  ;; Create the sun
  create-suns 1 [
    setxy (max-pxcor - 2) (max-pycor - 3)
    ;; change appearance based on intensity
    show-intensity
  ]

  ;; plot the initial state
  reset-ticks
  
  ;; <--- ЗМІНА ЛР2 (Варіант): Встановлюємо початкові значення циклу
  update-day-cycle
end


;; ---------------------------------------
;; go
;; ---------------------------------------

to go
  ;; Stop if all of the leaves are dead
  if not any? leaves [ stop ]

  ;; <--- ЗМІНА ЛР2 (Варіант): Оновлюємо добовий цикл на початку кожного тіку
  update-day-cycle
  
  ;; Have the wind blow and rain fall;
  ;; move any water in the sky, on the ground, and in the tree;
  ;; set the appearance of the sun on the basis of its intensity.
  make-wind-blow
  make-rain-fall
  move-water
  ask suns [ show-intensity ]

  ;; Now our leaves respond accordingly
  ask attached-leaves [
    adjust-water
    adjust-chlorophyll
    adjust-sugar
    
    ;; <--- ЗМІНА ЛР2 (Власна): Виклик перевірки на заморозки
    check-for-frost
    
    change-color
    change-shape
  ]

  ;; if the leaves are falling keep falling
  ask leaves [ fall-if-necessary ]

  ;; Leaves on the bottom should be killed off
  ask leaves with [ ycor <= bottom-line ] [
    set breed dead-leaves
  ]

  ;; Leaves without water should also be killed off
  ask leaves with [ water-level < 1 ] [
    set attachedness 0
  ]

  ;; Make sure that values remain between 0 - 100
  ask leaves [
    set chlorophyll (clip chlorophyll)
    set water-level (clip water-level)
    set sugar-level (clip sugar-level)
    set carotene (clip carotene)
    set anthocyanin (clip anthocyanin)
    set attachedness (clip attachedness)
  ]

  ;; increment the tick counter
  tick
end

to-report clip [ value ]
  if value < 0 [ report 0 ]
  if value > 100 [ report 100 ]
  report value
end

;; <--- ЗМІНА ЛР2 (Варіант): НОВА ПРОЦЕДУРА для добового циклу
;; ---------------------------------------
;; update-day-cycle: 
;; Розраховує поточні сонце та температуру на основі добового циклу.
;; ---------------------------------------
to update-day-cycle
  let time-of-day (ticks mod day-duration)
  let angle (time-of-day / day-duration) * 360
  
  ;; day-factor змінюється від 0 (ніч) до 1 (південь) і назад до 0
  let day-factor ( (sin (angle - 90)) + 1 ) / 2 
  
  ;; Встановлюємо поточну інтенсивність сонця на основі макс. значення зі слайдера
  set current-sun-intensity (sun-intensity * day-factor)
  
  ;; Температура коливається +/- 5 градусів навколо базової (зі слайдера)
  let temp-swing (day-factor * 10) - 5 ;; Коливання від -5 (ніч) до +5 (день)
  set current-temperature (temperature + temp-swing)
end

;; ---------------------------------------
;; make-wind-blow: When the wind blows,
;; ... (без змін)
;; ---------------------------------------

to make-wind-blow
  ask leaves [
    ifelse random 2 = 1
      [ rt 10 * wind-factor ]
      [ lt 10 * wind-factor ]
    set attachedness attachedness - wind-factor
  ]
end


;; ---------------------------------------
;; make-rain-fall: rain is a separate breed
;; ... (без змін)
;; ---------------------------------------

to make-rain-fall
  ;; Create new raindrops at the top of the world
  create-raindrops rain-intensity [
    setxy random-xcor max-pycor
    set heading 180
    fd 0.5 - random-float 1.0
    set size .3
    set color gray
    set location "falling"
    set amount-of-water 10
  ]
  ;; Now move all the raindrops, including
  ;; the ones we just created.
  ask raindrops [ fd random-float 2 ]
end


;; --------------------------------------------------------
;; move-water: water goes from raindrops -> ground,
;; ... (без змін)
;; --------------------------------------------------------

to move-water

  ;; We assume that the roots extend under the entire grassy area; rain flows through
  ;; the roots to the trunk
  ask raindrops with [ location = "falling" and pcolor = green ] [
    set location "in roots"
    face patch 0 ycor
  ]

  ;; Water flows from the trunk up to the central part of the tree.
  ask raindrops with [ location = "in roots" and pcolor = brown ] [
    face patch 0 0
    set location "in trunk"
  ]

  ;; Water flows out from the trunk to the leaves.  We're not going to
  ;; simulate branches here in a serious way
  ask raindrops with [ location = "in trunk" and patch-here = patch 0 0 ] [
    set location "in leaves"
    set heading random 360
  ]

  ;; if the raindrop is in the leaves and there is nothing left disappear
  ask raindrops with [ location = "in leaves" and amount-of-water <= 0.5 ] [
    die
  ]

  ;; if the raindrops are in the trunk or leaves and they are at a place
  ;; where they can no longer flow into a leaf then disappear
  ask raindrops with [
    (location = "in trunk" or location = "in leaves")
    and (ycor > max [ ycor ] of leaves or
         xcor > max [ xcor ] of leaves or
         xcor < min [ xcor ] of leaves)
  ] [
    die
  ]

end

;;---------------------------------------------------------
;; Turtle Procedures
;; --------------------------------------------------------

;; --------------------------------------------------------
;; show-intensity: Change how the sun looks to indicate
;; intensity of sunshine.
;; --------------------------------------------------------

to show-intensity  ;; sun procedure
  ;; <--- ЗМІНА ЛР2 (Варіант): Використовуємо 'current-sun-intensity' замість 'sun-intensity'
  set color scale-color yellow current-sun-intensity 0 150
  set size current-sun-intensity / 10
  set label word round current-sun-intensity "%"
  ifelse current-sun-intensity < 50
    [ set label-color yellow ]
    [ set label-color black  ]
end

;; --------------------------------------------------------
;; adjust-water: Handle the ups and downs of water within the leaf
;; --------------------------------------------------------

to adjust-water
  ;; Below a certain temperature, the leaf does not absorb
  ;; water any more.  Instead, it converts sugar and and water
  ;; to anthocyanin, in a proportion
  
  ;; <--- ЗМІНА ЛР2 (Варіант): Використовуємо 'current-temperature' замість 'temperature'
  if current-temperature < 10 [ stop ]

  ;; If there is a raindrop near this leaf with some water
  ;; left in it, then absorb some of that water
  let nearby-raindrops raindrops in-radius 2 with [ location = "in leaves" and amount-of-water >= 0 ]

  if any? nearby-raindrops [
    let my-raindrop min-one-of nearby-raindrops [ distance myself ]
    set water-level water-level + ([ amount-of-water ] of my-raindrop * 0.20)
    ask my-raindrop [
      set amount-of-water (amount-of-water * 0.80)
    ]
  ]

  ;; Reduce the water according to the temperature
  ;; <--- ЗМІНА ЛР2 (Варіант): Використовуємо 'current-temperature' замість 'temperature'
  if current-temperature > evaporation-temp [
    set water-level water-level - (0.5 * (current-temperature - evaporation-temp))
  ]

  ;; If the water level goes too low, reduce the attachedness
  if water-level < 25 [
    set attachedness attachedness - 1
  ]

end


;; ---------------------------------------
;; adjust-chlorophyll: It's not easy being green.
;; ...
;; ---------------------------------------

to adjust-chlorophyll

  ;; If the temperature is low, then reduce the chlorophyll
  ;; <--- ЗМІНА ЛР2 (Варіант): Використовуємо 'current-temperature' замість 'temperature'
  if current-temperature < 15 [
    set chlorophyll chlorophyll - (.5 * (15 - current-temperature))
  ]

  ;; If the sun is strong, then reduce the chlorophyll
  ;; <--- ЗМІНА ЛР2 (Варіант): Використовуємо 'current-sun-intensity' замість 'sun-intensity'
  if current-sun-intensity > 75 [
    set chlorophyll chlorophyll - (.5 * (current-sun-intensity - 75))
  ]

  ;; New chlorophyll comes from water and sunlight
  ;; <--- ЗМІНА ЛР2 (Варіант): Використовуємо 'current-temperature' та 'current-sun-intensity'
  if current-temperature > 15 and current-sun-intensity > 20 [
    set chlorophyll chlorophyll + 1
  ]

end


;; ---------------------------------------
;; adjust-sugar: water + sunlight + chlorophyll = sugar
;; ---------------------------------------

to adjust-sugar
  ;; If there is enough water and sunlight, reduce the chlorophyll
  ;; and water, and increase the sugar
  ;; <--- ЗМІНА ЛР2 (Варіант): Використовуємо 'current-sun-intensity' замість 'sun-intensity'
  if water-level > 1 and current-sun-intensity > 20 and chlorophyll > 1 [
    set water-level water-level - 0.5
    set chlorophyll chlorophyll - 0.5
    set sugar-level sugar-level + 1
    set attachedness attachedness + 5
  ]

  ;; Every tick of the clock, we reduce the sugar by 1
  set sugar-level sugar-level - 0.5
end

;; <--- ЗМІНА ЛР2 (Власна): НОВА ПРОЦЕДУРА для заморозків
;; ---------------------------------------
;; check-for-frost:
;; Якщо температура падає нижче точки замерзання,
;; листок пошкоджується, і його зв'язок слабшає.
;; ---------------------------------------
to check-for-frost ;; leaf procedure
  if current-temperature < frost-temperature [
    ;; Пошкодження від морозу - листок стає крихким
    let damage-factor (frost-temperature - current-temperature)
    set attachedness attachedness - (damage-factor * 2) ;; Прискорене опадання
    set chlorophyll chlorophyll - (damage-factor * 0.5) ;; Руйнування хлорофілу
  ]
end

;; ---------------------------------------
;; fall-if-necessary:  If a leaf is above the bottom row, make it fall down
;; ... (без змін)
;; ---------------------------------------

to fall-if-necessary
  if attachedness > 0 [ stop ]
  if ycor > bottom-line [
    let target-xcor (xcor + random-float wind-factor - random-float wind-factor)
    facexy target-xcor bottom-line
    fd random-float (.7 * max (list wind-factor .5))
  ]
end


;; ---------------------------------------
;; change-color: Because NetLogo has a limited color scheme,
;; ...
;; ---------------------------------------

to change-color
  ;; If the temperature is low, then we turn the
  ;; sugar into anthocyanin
  ;; <--- ЗМІНА ЛР2 (Варіант): Використовуємо 'current-temperature' замість 'temperature'
  if current-temperature < 20 and sugar-level > 0 and water-level > 0 [
    set sugar-level sugar-level - 1
    set water-level water-level - 1
    set anthocyanin anthocyanin + 1
  ]

  ;; If we have more than 50 percent chlorophyll, then
  ;; we are green, and scale the color accordingly
  ifelse chlorophyll > 50 [
    set color scale-color green chlorophyll 150 -50
  ] [
    ;; If we are lower than 50 percent chlorophyll, then
    ;; we have yellow (according to the carotene), red (according
    ;; to the anthocyanin), or orange (if they are about equal).

    ;; If we have roughly equal anthocyanin and carotene,
    ;; then the leaves should be in orange.
    if abs (anthocyanin - carotene ) < 10 [
      set color scale-color orange carotene 150 -50
    ]
    if anthocyanin > carotene + 10 [
      set color scale-color red anthocyanin 170 -50
    ]
    if carotene > anthocyanin + 10 [
      set color scale-color yellow carotene 150 -50
    ]
  ]
end

to change-shape ;; (без змін)
  ifelse leaf-display-mode = "solid" [
    set shape "default"
  ] [
    if leaf-display-mode = "chlorophyll" [
      set-shape-for-value chlorophyll
    ]
    if leaf-display-mode = "water" [
      set-shape-for-value water-level
    ]
    if leaf-display-mode = "sugar" [
      set-shape-for-value sugar-level
    ]
    if leaf-display-mode = "carotene" [
      set-shape-for-value carotene
    ]
    if leaf-display-mode = "anthocyanin" [
      set-shape-for-value anthocyanin
    ]
    if leaf-display-mode = "attachedness" [
      set-shape-for-value attachedness
    ]
  ]
end

;; returns all leaves still attached
to-report attached-leaves ;; (без змін)
  report leaves with [attachedness > 0]
end

;; makes the leaf appear to be more or less filled depending on value
to set-shape-for-value [ value ] ;; (без змін)
  ifelse value > 75 [
    set shape "default"
  ] [
    ifelse value <= 25 [
      set shape "default one-quarter"
    ] [
      ifelse value <= 50 [
        set shape "default half"
      ] [
        set shape "default three-quarter"
      ]
    ]
  ]
end


; Copyright 2005 Uri Wilensky.
; See Info tab for full copyright and license.
