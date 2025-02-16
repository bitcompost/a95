;; a95
;; Copyright (C) 2025  bitcompost

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License along
;; with this program; if not, see <https://www.gnu.org/licenses/>.

(set keyboard false)
(set win-key false)
(set alt-key false)
(set font-size false)
(set fonts [:unifont-15.1.04.otf
            :unifont_upper-15.1.04.otf])

(set themes {})

(set segments {})
(set primary-ids {})
(set connection-points {})
(set windows [])
(set stack [])
(set selected false)
(set switch-running false)
(set switch-current 0)
(set alt-pressed false)
(set win-pressed false)
(set last-key false)

(set menu false)
(set overlay false)

(set mouse-pressed false)

(set panel-parts [])
(set panel-listeners [])
(set menu-icon false)
(set panel-win-btns-start 48)
(set panel-win-btns-end 256)
(set panel-win-btn-pressed false)
(set panel-win-btn-pressed-prev false)
(set panel-win-btn-clicked false)

(set clipboard-temp "")
(set clipboard-last "")

(set speech false)

; Config

(fn _G.config-load []
  (keyboard:kbd_repeat 10 2)
  (keyboard:load_keymap (get_key :keymap))

  (set win-key (or (get_key :win_key) :lmeta))
  (set alt-key (or (get_key :alt_key) :lalt))
  (set font-size (or (get_key :font_size) 16)))

; Accessibility

(fn _G.say [text]
  (when (and speech (valid_vid speech))
    (delete_image speech))
  (set speech (launch_decode 
                nil
                (.. "text="
                    (string.gsub (or text "") ":" " colon ")
                    ":protocol=t2s")
                (fn [source status] nil)))
  (print text))

; Window management

(fn _G.make-window [x y w h theme]
  (local window {:segments []})
  (set window.w (or w 800))
  (set window.h (or h 600))
  (set window.x (or x (/ (- VRESW window.w) 2)))
  (set window.y (or y (/ (- VRESH window.h) 2)))
  (set window.theme (or theme :redmond))
  (set window.frame-part-vids [])
  (set window.frame-listeners [])
  (set window.left 0)
  (set window.top 0)
  (set window.right window.w)
  (set window.bottom window.h)
  (table.insert windows window)
  window)

(fn _G.window-delete [window]
  (when window
    (each [_ vid (ipairs window.segments)]
      (segment-delete vid))
    (table.remove_match windows window)
    (table.remove_match stack window)
    (when (= selected window)
      (set selected nil)
      (window-select-next))))

(fn _G.window-select [window]
  (set switch-running false)
  (when (and window
             window.inited
             (valid_vid window.active-vid)
             (. segments window.active-vid)
             (. segments window.active-vid :inited))
    (say (or (. segments window.active-vid :id) ""))
    (local old selected)
    (set selected window)
    (table.remove_match stack window)
    (table.insert stack 1 window)
    (when (and old old.inited)
      (set old.selected nil)
      (when (not old.minimized)
        (window-decorate old)))
    (set window.selected true)
    (set window.minimized false)
    (window-decorate window))
  (panel-rebuild)
  (stack-reorder))

(fn _G.window-select-next []
  (var sel nil)
  (each [_ window (ipairs stack)]
    (when (and (not window.minimized)
               (not sel))
      (set sel window)))
  (window-select sel))

(fn _G.resize-start [window x y w h]
  (when (and window.inited (> w 50) (> h 16))
    (set window.in-resize {:x x :y y :w w :h h})
    (when window.inited
      (window-decorate window))))

(fn _G.resize-finish [window]
  (when window.inited
    (set window.last-resize window.in-resize)
    (each [_ vid (ipairs window.segments)]
      (when (valid_vid vid)
        (target_displayhint
          vid window.in-resize.w window.in-resize.h nil {:ppcm VPPCM})))
    (set window.in-resize nil)))

(fn _G.window-maximize [window]
  (when (and window.inited (valid_vid window.active-vid))
    (if (not window.maximized)
      (do (set window.saved-x window.x)
          (set window.saved-y window.y)
          (set window.saved-w window.w)
          (set window.saved-h window.h)
          (local x (- window.left))
          (local y (- window.top))
          (local w (+ VRESW window.left (- window.w window.right)))
          (local h (+ VRESH window.top (- window.h window.bottom)))
          (resize-start window x y w h)
          (resize-finish window)
          (set window.maximized true))
      :else
      (do (resize-start window 
                        window.saved-x window.saved-y
                        window.saved-w window.saved-h)
          (resize-finish window)
          (set window.maximized nil)))))

(fn _G.window-minimize [window]
  (when (and window.inited (valid_vid window.active-vid))
    (set window.minimized true)
    (window-delete-decorations window)
    (hide_image window.active-vid)
    (set window.selected nil)
    (set selected nil)
    (window-select-next)))

(fn _G.window-move [window x y]
  (when (and window.inited (valid_vid window.active-vid))
    (each [_ vid (ipairs window.segments)]
      (when (valid_vid vid)
        (move_image vid x y)))
    (set window.x x)
    (set window.y y)))

(fn _G.window-drag [window part]
  (when (and window window.inited)
    (local (x y) (mouse_xy))
    (set window.dragging part)
    (set window.drag-start {:x x :y y :w window.w :h window.h})
    (set window.pressed part)
    (set window.click-offset {:x (- window.x x) :y (- window.y y)})))

(fn _G.window-switch []
  (when (> (# stack) 0)
    (when (not switch-running)
      (set switch-running true)
      (set switch-current 1))
    (set switch-current (+ 1 (math.fmod switch-current
                                        (# stack))))
    (if alt-pressed
      (stack-reorder (. stack switch-current))
      (window-select (. stack switch-current)))))

(fn _G.window-new-segment [segment]
  (local
    listener
    {:name :mouse-handler
     :vid segment.vid
     :input (fn [ctx tbl] (target_input segment.vid tbl))
     :own (fn [ctx tgt] (= segment.vid tgt))
     :button (fn [ctx v ind pressed x y]
               (when (and pressed selected (not= segment.window selected))
                 (window-select segment.window))
               (when pressed
                 (stack-reorder))
               (when (and pressed (= ind MOUSE_MBUTTON))
                 (clipboard-paste segment.vid clipboard-last))
               (if
                 (and pressed selected alt-pressed (= ind MOUSE_LBUTTON))
                 (window-drag segment.window :title)

                 :else
                 (target_input segment.vid
                               {:devid 0
                                :subid ind
                                :mouse true
                                :kind :digital
                                :active pressed})))
     :motion (fn [ctx v x y rx ry]
               (local x (if segment.window.x (- x segment.window.x) x))
               (local y (if segment.window.y (- y segment.window.y) y))
               (target_input segment.vid
                             {:devid 0
                              :subid 0
                              :kind :analog
                              :mouse true
                              :samples [x rx]})
               (target_input segment.vid
                             {:devid 0
                              :subid 1
                              :kind :analog
                              :mouse true
                              :samples [y ry]}))
     :mouse true})
  (mouse_addlistener listener [:motion :button])
  (set segment.mouse-handler listener)
  (set (. segments segment.vid) segment)
  (when segment.is-primary
    (set (. primary-ids segment.primary-id) segment)))

(fn _G.segment-init [vid aid]
  (local segment (if (valid_vid vid) (. segments vid)))
  (when segment
    (set segment.aid aid)
    (target_displayhint vid segment.window.w segment.window.h nil {:ppcm VPPCM})
    ;(if (= segment.id "netsurf")
    ;  (set segment.origo_ll nil))
    (image_set_txcos_default vid segment.origo_ll)
    (local window segment.window)
    (table.insert window.segments vid)
    (set segment.inited true)
    (move_image vid segment.window.x segment.window.y)
    (segment-activate vid)
    (when (not window.inited)
      (set window.inited true)
      (window-select window))))

(fn _G.segment-delete [vid]
  (local segment (if (valid_vid vid) (. segments vid)))
  (when segment
    (mouse_droplistener segment.mouse-handler)
    (set (. segments vid) nil)
    (when segment.is-primary
      (set (. primary-ids segment.primary-id) nil))
    (when segment.inited
      (table.remove_match segment.window.segments vid)
      (when (= vid segment.window.active-vid)
        ;; clear listeners and frame parts lists because they are attached to active-vid
        (each [_ listener (ipairs segment.window.frame-listeners)]
          (mouse_droplistener listener))
        (set segment.window.frame-listeners [])
        (each [_ old-vid (ipairs segment.window.frame-part-vids)]
          (when (valid_vid old-vid)
            (delete_image old-vid)))
        (set segment.window.frame-part-vids []))
      (if (= 0 (# segment.window.segments))
        (window-delete segment.window)
        (segment-activate (. segment.window.segments (# segment.window.segments)))))
    (delete_image vid)))

(fn _G.segment-migrate [vid window]
  (local segment (if (valid_vid vid) (. segments vid)))
  (when segment
    (table.remove_match segment.window.segments vid)
    (when (= vid segment.window.active-vid)
      ;; clear listeners and frame parts lists because they are attached to active-vid
      (each [_ listener (ipairs segment.window.frame-listeners)]
        (mouse_droplistener listener))
      (set segment.window.frame-listeners [])
      (each [_ old-vid (ipairs segment.window.frame-part-vids)]
        (when (valid_vid old-vid)
          (delete_image old-vid)))
      (set segment.window.frame-part-vids []))
    (if (= 0 (# segment.window.segments))
      (window-delete segment.window)
      (segment-activate (. segment.window.segments (# segment.window.segments))))
    (hide_image vid)
    (set segment.window window)
    (set segment.inited nil)
    (if (or (< window.w (. (image_storage_properties vid) :width))
            (< window.h (. (image_storage_properties vid) :height)))
      (target_displayhint vid window.w window.h nil {:ppcm VPPCM})
      (segment-init vid segment.aid))))

(fn _G.segment-activate [vid]
  (local segment (if (valid_vid vid) (. segments vid)))
  (when (and segment segment.inited)
    (say (or segment.id ""))
    (local window segment.window)
    (local old window.active-vid)
    (set window.active-vid vid)
    (when (and (valid_vid old)
               (. segments old)
               (. segments old :inited))
      (set (. segments old :active) nil)
      (hide_image old))
    (show_image vid)
    (set segment.active true)
    (window-decorate window)
    (panel-rebuild)
    (stack-reorder)))

(fn _G.segment-switch []
  (when (and selected selected.inited (valid_vid selected.active-vid))
    (var new-active-vid selected.active-vid)
    (each [i segment (ipairs selected.segments)]
      (when (= segment selected.active-vid)
        (set new-active-vid (. selected.segments
                               (+ 1 (math.fmod i (# selected.segments)))))))
    (segment-activate new-active-vid)))

(fn _G.segment-resize [vid w h]
  (local segment (if (valid_vid vid) (. segments vid)))
  (when segment
    (resize_image vid w h)
    (local window segment.window)
    (when (= vid window.active-vid)
      (set window.w w)
      (set window.h h)
      (each [_ c (ipairs window.segments)]
        (when (and (valid_vid c) (~= c window.active-vid))
          (target_displayhint c w h nil {:ppcm VPPCM})))
      (when window.last-resize
        (set window.x window.last-resize.x)
        (set window.y window.last-resize.y)
        (set window.in-resize nil)
        (set window.last-resize nil)
        (window-move window window.x window.y))
      (when window.inited
        (window-decorate window)
        (stack-reorder)))))

(fn _G.clipboard-paste [vid msg]
  (local segment (if (valid_vid vid) (. segments vid)))
  (when segment
    (when (not (valid_vid segment.clipboard))
      (set segment.clipboard (define_nulltarget
                              vid
                              :clipboard
                              (fn [source status]
                                (case status
                                  {:kind :terminated}
                                  (do (set segment.clipboard nil)
                                      (delete_image source))))))
      (when (valid_vid segment.clipboard)
        (link_image segment.clipboard vid)))
    (when (valid_vid segment.clipboard)
      (target_input segment.clipboard msg))))

(fn _G.clipboard-handler [source status]
  (case status
    {:kind :terminated}
    (delete_image source)

    {:kind :message :message msg}
    (do
      (set clipboard-temp (.. clipboard-temp msg))
      (when (not status.multipart)
        (set clipboard-last clipboard-temp)
        (set clipboard-temp "")))))

(fn _G.make-segment-event-handler [primary-id is-primary primary-window embedder]
  (fn segment-event-handler [source status]
    (var window (?. segments source :window))
    (when (not window)
      (set window (?. primary-ids primary-id :window)))
    (when (and (not window) is-primary)
      (set window primary-window))
    (when (not window)
      (delete_image source))
    (when window
      (case status
        {:kind :registered :title title}
        (window-new-segment {:vid source
                             :id (if is-primary primary-id title)
                             :is-primary is-primary
                             :primary-id primary-id
                             :embedder embedder
                             :window window})

        {:kind :preroll}
        (do
          (target_displayhint source window.w window.h nil {:ppcm VPPCM})
          (each [i font (ipairs fonts)]
            (target_fonthint source font (/ (* 10 font-size) VPPCM) 0 (> i 1))))

        {:kind :ident :message id}
        (do
          (when (not is-primary)
            (set (. segments source :id) id))
          (when (. segments source :inited)
            (window-decorate window)
            (panel-rebuild)
            (stack-reorder)))

        {:kind :resized :width w :height h}
        (do
          (set (. segments source :origo_ll) status.origo_ll)
          (segment-resize source w h)
          (when (not (. segments source :inited))
            (segment-init source status.source_audio)))

        {:kind :segment_request :segkind :clipboard}
        (do
          (local vid (accept_target clipboard-handler))
          (when (valid_vid vid)
            (link_image vid source)))

        {:kind :segment_request}
        (accept_target (make-segment-event-handler primary-id
                                                   false
                                                   false
                                                   source))

        {:kind :connected}
        (set (. connection-points primary-id)
             (target_alloc (.. "arcan-" primary-id)
                           (make-segment-event-handler primary-id)))

        {:kind :terminated}
        (segment-delete source)))))

(fn _G.launch-app [id window]
  (var window window)
  (var primary-id id)
  (var i 1)
  (while (. primary-ids primary-id)
    (set i (+ i 1))
    (set primary-id (.. id i)))
  (when (not window)
    (set window (make-window)))
  (if (= id :terminal)
    (launch_avfeed (.. "palette=solarized-white"
                       ":env=ARCAN_CONNPATH=arcan-"
                       primary-id)
                   :terminal
                   (make-segment-event-handler primary-id
                                               true
                                               window))
    (launch_target id (make-segment-event-handler primary-id
                                                  true
                                                  window)))
  (when (not (. connection-points primary-id))
    (set (. connection-points primary-id)
         (target_alloc (.. "arcan-" primary-id)
                       (make-segment-event-handler primary-id)))))

(fn _G.stack-reorder [win-on-top]
  (panel-raise)
  (when win-on-top
    (table.insert stack 1 win-on-top)
    (when win-on-top.minimized
      (window-decorate win-on-top)))
  (each [i _ (ipairs stack)]
    (local window (. stack (- (# stack) 
                              (- i 1))))
    (when (and window.minimized
               (not= window win-on-top))
      (window-delete-decorations window)
      (hide_image window.active-vid))
    (each [_ part (ipairs window.frame-part-vids)]
      (when (valid_vid part)
        (order_image part 1)))
    (when (valid_vid window.active-vid)
      (order_image window.active-vid 1)))
  (when win-on-top
    (table.remove stack 1)
    (say (or (. segments win-on-top.active-vid :id) ""))))

; Window decoradions

(fn _G.make-tabbed-frame [frame num-tabs]
  (var title nil)
  (local new-frame [])
  (each [_ part (ipairs frame)]
    (if (= part.type :title)
      (set title part)
      (table.insert new-frame part)))
  (var i 1)
  (while (<= i num-tabs)
    (local tab-title [])
    (each [k v (pairs title)]
      (set (. tab-title k) v))
    (set tab-title.tab-number i)
    (table.insert new-frame i tab-title)
    (set i (+ i 1)))
  new-frame)

(fn _G.window-delete-decorations [window]
  (each [_ listener (ipairs window.frame-listeners)]
    (mouse_droplistener listener))
  (set window.frame-listeners [])
  (each [_ old-vid (ipairs window.frame-part-vids)]
    (when (valid_vid old-vid)
      (delete_image old-vid)))
  (set window.frame-part-vids []))

(fn _G.window-decorate [window]
  (window-delete-decorations window)
  (set window.left 0)
  (set window.top 0)
  (set window.right window.w)
  (set window.bottom window.h)
  (set window.id (?. segments window.active-vid :id))
  ;; window background
  (local bg (fill_surface window.w window.h 198 198 198))
  (link_image bg window.active-vid ANCHOR_UL)
  (move_image bg 0 0)
  (order_image bg 1)
  (show_image bg)
  (table.insert window.frame-part-vids bg)
  (local theme (. themes window.theme))
  (var frame theme.frame)
  (local num-tabs (# window.segments))
  (when theme.tabbed
    (set frame (make-tabbed-frame frame num-tabs)))
  (each [_ part (ipairs frame)]
    (fn eval-attribute [attr]
      (local segment (if part.tab-number 
                      (. segments (. window.segments part.tab-number))
                      (. segments window.active-vid)))
      (case (type attr)
        :function (attr segment)
        :table (or (and (= part.type window.pressed) (. attr 3))
                   (and segment.active (= window selected) (. attr 2))
                   (. attr 1))
        _ attr))
    (local text        (eval-attribute part.text))
    (local text-x      (eval-attribute part.text-x))
    (local text-y      (eval-attribute part.text-y))
    (local color       (eval-attribute part.foreground))
    (local img         (eval-attribute part.background))
    (local top-edge    (eval-attribute part.top-edge))
    (local bottom-edge (eval-attribute part.bottom-edge))
    (local left-edge   (eval-attribute part.left-edge))
    (local right-edge  (eval-attribute part.right-edge))
    (local width       (eval-attribute part.width))
    (local height      (eval-attribute part.height))
    (var w (or width
               (and left-edge right-edge (- window.w left-edge right-edge))
               (. (image_storage_properties img) :width)))
    (var h (or height
               (and top-edge bottom-edge (- window.h top-edge bottom-edge))
               (. (image_storage_properties img) :height)))
    (var x (or left-edge
               (and right-edge (- window.w (+ right-edge w)))
               0))
    (var y (or top-edge
               (and bottom-edge (- window.h (+ bottom-edge h)))
               0))
    (when part.tab-number
      (set w (/ w num-tabs))
      (set x (+ x (* (- part.tab-number 1)
                     w)))
      (set w (+ w 1)))
    (when (< x window.left) (set window.left x))
    (when (< y window.top) (set window.top y))
    (when (> (+ x w) window.right) (set window.right (+ x w)))
    (when (> (+ y h) window.bottom) (set window.bottom (+ y h)))
    (local part-vid (null_surface w h))
    (image_sharestorage img part-vid)
    (switch_default_texmode TEX_REPEAT TEX_REPEAT part-vid)
    (link_image part-vid window.active-vid ANCHOR_UL)
    (move_image part-vid x y)
    (show_image part-vid)
    (table.insert window.frame-part-vids part-vid)
    (local
      listener
      {:name :mouse-handler
       :vid part-vid
       :own (fn [ctx tgt] (= part-vid tgt))
       :button (fn [ctx tgt ind pressed x y]
                 (when pressed
                   (set window.dragging part.type)
                   (set window.drag-start {:x x :y y :w window.w :h window.h})
                   (set window.pressed part.type)
                   (set window.click-offset {:x (- window.x x) :y (- window.y y)})
                   (when (and part.tab-number 
                              (not= (. window.segments part.tab-number)
                                    window.active-vid))
                     (segment-activate (. window.segments part.tab-number)))
                   (when (not window.selected)
                     (window-select window))
                   (window-decorate window)
                   (stack-reorder))
                 (when (not pressed)
                   (set window.released part.type)))})
    (table.insert window.frame-listeners listener)
    (mouse_addlistener listener [:button])
    (when (and part.tab-number
               (> part.tab-number 1))
      ; draw tab separator
      (local line (fill_surface 1 h 0 0 0))
      (link_image line window.active-vid ANCHOR_UL)
      (move_image line x y)
      (order_image line 1)
      (show_image line)
      (table.insert window.frame-part-vids line))
    (when text
      (each [_ i (ipairs [0 1])] ; render twice to make text bold
        (local text-vid (render_text
                          (.. "\\ffonts/unifont-15.1.04.otf,12"
                              ; (tostring (/ font-size (* FONT_PT_SZ VPPCM 0.1)))
                              "\\#"
                              color
                              " "
                              text)))
        (link_image text-vid window.active-vid ANCHOR_UL)
        (move_image text-vid (+ x (or text-x 0) i)
                             (+ y (or text-y 0)))
        (crop_image text-vid (- w text-x) h)
        (order_image text-vid 1)
        (show_image text-vid)
        (table.insert window.frame-part-vids text-vid)
        (local text-listener {:name :mouse-handler
                              :vid text-vid
                              :own (fn [ctx tgt] (= text-vid tgt))
                              :button listener.button})
        (table.insert window.frame-listeners text-listener)
        (mouse_addlistener text-listener [:button]))))
  (order_image window.active-vid 1)
  (show_image window.active-vid)
  (case window.in-resize
    {:x x :y y :w w :h h}
    ;;draw a square
    (do (local top1    (fill_surface w 1 0   0   0))
        (local top2    (fill_surface w 1 255 255 255))
        (local bottom1 (fill_surface w 1 0   0   0))
        (local bottom2 (fill_surface w 1 255 255 255))
        (local left1   (fill_surface 1 h 0   0   0))
        (local left2   (fill_surface 1 h 255 255 255))
        (local right1  (fill_surface 1 h 0   0   0))
        (local right2  (fill_surface 1 h 255 255 255))
        (move_image top1    x          y)
        (move_image top2    x          (+ y 1))
        (move_image bottom1 x          (+ y h))
        (move_image bottom2 x          (+ y h -1))
        (move_image left1   x          y)
        (move_image left2   (+ x 1)    y)
        (move_image right1  (+ x w)    y)
        (move_image right2  (+ x w -1) y)
        (each [_ line (ipairs [top1 top2 bottom1 bottom2
                               left1 left2 right1 right2])]
          (order_image line 1)
          (show_image line)
          (table.insert window.frame-part-vids line)))))

; Menu

(fn _G.menu-delete []
  (when menu
    (each [_ part (ipairs menu.parts)]
      (when (valid_vid part)
        (delete_image part)))
    (set menu nil)
    (say "")))

(fn _G.menu-rebuild []
  (when menu
    (each [_ part (ipairs menu.parts)]
      (when (valid_vid part)
        (delete_image part)))
    (set menu.parts [])
    (local height (* (# menu.buttons)
                     (+ font-size 8)))
    (local background1 (fill_surface menu.width height 0 0 0))
    (move_image background1 menu.x menu.y)
    (order_image background1 1)
    (show_image background1)
    (table.insert menu.parts background1)
    (local background2 (fill_surface (- menu.width 2) (- height 2) 255 255 255))
    (move_image background2 (+ 1 menu.x) (+ 1 menu.y))
    (order_image background2 1)
    (show_image background2)
    (table.insert menu.parts background2)
    (local selected-bg (fill_surface (- menu.width 2) (+ font-size 6) 0 0 0))
    (move_image selected-bg (+ 1 menu.x) (+ 1 menu.y (* (- menu.selected 1)
                                                        (+ font-size 8))))
    (order_image selected-bg 1)
    (show_image selected-bg)
    (table.insert menu.parts selected-bg)
    (each [i btn (ipairs menu.buttons)]
      (each [_ n (ipairs [1 2])] ; render twice to make text bold
        (local color (if (= i menu.selected) :ffffff :000000))
        (local text1 (render_text
                       (string.format
                         "\\ffonts/unifont-15.1.04.otf,%i\\#%s %s"
                         (+ 0.5 (/ font-size (* FONT_PT_SZ VPPCM 0.1)))
                         color
                         btn.name)))
        (move_image text1 (+ menu.x n) (+ 4 menu.y (* (- i 1)
                                                      (+ font-size 8))))
        (crop_image text1 (- menu.width 40) (+ font-size 8))
        (order_image text1 1)
        (show_image text1)
        (table.insert menu.parts text1)
        (local text2 (render_text
                       (string.format
                         "\\ffonts/unifont-15.1.04.otf,%i\\#%s %s"
                         (+ 0.5 (/ font-size (* FONT_PT_SZ VPPCM 0.1)))
                         color
                         (if
                           (= btn.key :BACKQUOTE) "`"
                           (= btn.key nil)        " "
                           :else                  btn.key))))
        (move_image text2
                    (+ menu.x n (- menu.width 40))
                    (+ menu.y 4 (* (- i 1)
                                   (+ font-size 8))))
        (crop_image text2 menu.width (+ font-size 8))
        (order_image text2 1)
        (show_image text2)
        (table.insert menu.parts text2)))))

(fn _G.make-menu [x y buttons]
  (menu-delete)
  (set mouse-pressed nil)
  (set menu {:x x
             :y y
             :width 200
             :buttons buttons
             :parts []
             :selected 1})
  (var descr "menu, ")
  (each [_ button (ipairs buttons)]
    (set descr (.. descr
                   button.name
                   " "
                   (or button.key "")
                   ", ")))
  (say descr)
  (menu-rebuild))

(fn _G.make-window-menu [vid]
  (local segment (if (valid_vid vid) (. segments vid)))
  (when segment
    (make-menu
      segment.window.x
      segment.window.y
      [{:name "Close"
        :key :F4
        :fn (fn [] (segment-delete vid))}
       {:name "Minimize"
        :key :m
        :fn (fn [] (window-minimize segment.window))}
       {:name "Maximize"
        :key :a
        :fn (fn [] (window-maximize segment.window))}
       {:name "Move"
        :key :o
        :fn (fn [] (window-drag segment.window :title))}
       {:name "Resize"
        :key :r
        :fn (fn [] (window-drag segment.window :bottom-right-corner))}
       {:name "Theme"
        :key nil
        :fn (fn []
              (var opts [])
              (each [theme _ (pairs themes)]
                (table.insert opts {:name theme
                                    :fn (fn []
                                          (when (and selected selected.inited)
                                            (set selected.theme theme)
                                            (window-decorate selected)))}))
              (make-menu segment.window.x segment.window.y opts))}
       {:name "Switch window"
        :key :TAB
        :fn window-switch}
       {:name "Switch tab"
        :key :BACKQUOTE
        :fn segment-switch}
       {:name "Migrate tab"
        :key nil
        :fn (fn []
              (var opts [{:name "New window"
                          :fn (fn []
                                (segment-migrate vid (make-window)))}])
              (each [_ window (ipairs windows)]
                (when (not= window segment.window)
                  (table.insert
                    opts
                    {:name (or (?. segments window.active-vid :id) "")
                     :fn (fn [] (segment-migrate vid window))})))
              (make-menu segment.window.x segment.window.y opts))}])))

(fn _G.make-main-menu []
  (local options
         [{:name "Terminal"
           :fn (fn [] (launch-app :terminal))}
          {:name "Screen Resolution"
           :key nil
           :fn (fn []
                 (var opts [])
                 (local modes (video_displaymodes 0))
                 (each [i mode (ipairs modes)]
                   (table.insert opts {:name (string.format "%ix%i @ %f"
                                                            mode.width
                                                            mode.height
                                                            mode.refresh)
                                       :fn (fn [] 
                                             (video_displaymodes 0 mode.modeid)
                                             (resize_video_canvas mode.width
                                                                  mode.height))}))
                 (local h (* (# opts) (+ font-size 8)))
                 (make-menu 0 (- VRESH h 48) opts))}])
  (each [i target (ipairs (list_targets))]
    (table.insert options (+ i 1) {:name target
                                   :fn (fn [] (launch-app target))}))
  (local h (* (# options) (+ font-size 8)))
  (make-menu 0 (- VRESH h 48) options))

; Overlay

(fn _G.overlay-delete []
  (when overlay
    (each [_ part (ipairs overlay.parts)]
      (when (valid_vid part)
        (delete_image part)))
    (set overlay nil)
    (say "")))

(fn _G.overlay-rebuild []
  (when overlay
    (each [_ part (ipairs overlay.parts)]
      (when (valid_vid part)
        (delete_image part)))
    (local str (string.format
                 "\\ffonts/unifont-15.1.04.otf,%i\\#%s %s"
                 (+ 0.5 (/ font-size (* FONT_PT_SZ VPPCM 0.1)))
                 :000000
                 (string.gsub (.. overlay.text
                                  (if overlay.input
                                    (.. overlay.input "_")
                                    ""))
                              "\n"
                              "\\r\\n")))
    (local (w h) (text_dimensions str))
    (each [_ n (ipairs [0 1])] ; render twice to make text bold
      (local text (render_text str))
      (move_image text n overlay.y)
      (order_image text 2)
      (show_image text)
      (table.insert overlay.parts text))
    (local bg (fill_surface VRESW h 255 255 255))
    (move_image bg 0 overlay.y)
    (order_image bg 1)
    (show_image bg)
    (table.insert overlay.parts bg)))

(fn _G.make-overlay [y text input fun]
  (overlay-delete)
  (set mouse-pressed nil)
  (set overlay {:y y
                :text text
                :parts []
                :input input
                :fun fun})
  (say text)
  (overlay-rebuild))

(fn _G.make-arcan-cmd-overlay [text]
  (make-overlay
    0
    (.. (or text "") "> ")
    ""
    (fn [input]
      (local (ok result)
             (pcall  (fn []
                      (fennel.eval input {:allowedGlobals false}))))
      (make-arcan-cmd-overlay (.. (fennel.view result) "\n")))))

; Panel

(fn _G.panel-raise []
  (each [_ part (ipairs panel-parts)]
    (when (valid_vid part)
      (order_image part 1)))
  (order_image menu-icon 1))

(fn _G.panel-rebuild []
  (each [_ listener (ipairs panel-listeners)]
    (mouse_droplistener listener))
  (set panel-listeners [])
  (each [_ part (ipairs panel-parts)]
    (when (valid_vid part)
      (delete_image part)))
  (set panel-parts [])
  (local panel (fill_surface VRESW 48 198 198 198))
  (order_image panel 1)
  (move_image panel 0 (- VRESH 48))
  (local panel-listener
    {:name :panel-handler
     :vid panel
     :own (fn [ctx tgt] (= panel tgt))
     :button (fn [ctx tgt ind pressed x y]
               (panel-raise))})
  (mouse_addlistener panel-listener [:button])
  (table.insert panel-listeners panel-listener)
  (table.insert panel-parts panel)
  (show_image panel)
  (order_image menu-icon 1)
  (move_image menu-icon 0 (- VRESH 48))
  (show_image menu-icon)
  (local button-listener
    {:name :button-handler
     :vid menu-icon
     :own (fn [ctx tgt] (= menu-icon tgt))
     :button (fn [ctx tgt ind pressed x y]
               (panel-raise)
               (when pressed
                 (move_image menu-icon 2 (- VRESH 46)))
               (when (not pressed)
                 (move_image menu-icon 0 (- VRESH 48))
                 (make-main-menu)))})
  (mouse_addlistener button-listener [:button])
  (table.insert panel-listeners button-listener)
  (panel-win-buttons-rebuild
    panel-win-btns-start
    (- VRESH 48)
    (- VRESW panel-win-btns-start panel-win-btns-end)
    48))

(fn _G.panel-win-buttons-rebuild [x y w h]
  (local btn-height (+ font-size 8))
  (local num-rows (math.floor (/ h btn-height)))
  (local num-cols (math.ceil (/ (# windows) num-rows)))
  (local btn-width (math.floor (/ w num-cols)))
  (each [i window (ipairs windows)]
    (local row (math.fmod (- i 1) num-rows))
    (local col (math.floor (/ (- i 1) num-rows)))
    (local btn-x (+ x (* col btn-width)))
    (local btn-y (+ y (* row btn-height)))
    (local bg1 (fill_surface (- btn-width 2) (- btn-height 2) 0 0 0))
    (move_image bg1 (+ btn-x 1) (+ btn-y 1))
    (order_image bg1 1)
    (show_image bg1)
    (table.insert panel-parts bg1)
    (var bg2 nil)
    (var text-color :ffffff)
    (when (and (not= panel-win-btn-pressed i)
               (not window.selected))
      (set text-color :000000)
      (set bg2 (fill_surface (- btn-width 4) (- btn-height 4) 255 255 255))
      (move_image bg2 (+ btn-x 2) (+ btn-y 2))
      (order_image bg2 1)
      (show_image bg2)
      (table.insert panel-parts bg2))
    (local str (string.format
                 "\\ffonts/unifont-15.1.04.otf,%i\\#%s %s"
                 (+ 0.5 (/ font-size (* FONT_PT_SZ VPPCM 0.1)))
                 text-color
                 (or (?. segments window.active-vid :id)
                     "")))
    (local text1 (render_text str))
    (crop_image text1 (- btn-width 4) (- btn-height 4))
    (move_image text1 (+ btn-x 2) (+ btn-y 2))
    (order_image text1 1)
    (show_image text1)
    (local text2 (render_text str))
    (crop_image text2 (- btn-width 4) (- btn-height 4))
    (move_image text2 (+ btn-x 3) (+ btn-y 2))
    (order_image text2 1)
    (show_image text2)
    (table.insert panel-parts text1)
    (table.insert panel-parts text2) 
    (local button-listener
      {:name :button-handler
       :vid bg1
       :own (fn [ctx tgt] (or (= bg1 tgt)
                              (and bg2 (= bg2 tgt))
                              (= text1 tgt)
                              (= text2 tgt)))
       :button (fn [ctx tgt ind pressed x y]
                 (when pressed
                   (set panel-win-btn-pressed i))
                 (when (not pressed)
                   (when (= panel-win-btn-pressed i)
                     (set panel-win-btn-clicked [i ind]))
                   (set panel-win-btn-pressed false)))})
    (mouse_addlistener button-listener [:button])
    (table.insert panel-listeners button-listener)))

; Input

(fn _G.panel-handle-mouse [input]
  (case panel-win-btn-clicked
    [i btn]
    (do (set panel-win-btn-clicked false)
        (if (?. windows i :selected)
          (window-minimize (. windows i))
          (window-select (. windows i))))
    _
    (when (not= panel-win-btn-pressed panel-win-btn-pressed-prev)
      (panel-rebuild)))
  (set panel-win-btn-pressed-prev panel-win-btn-pressed))

(fn _G.menu-handle-mouse [input]
  (when menu
    (local (x y) (mouse_xy))
    (local mouse-on-menu (and (>= x menu.x)
                              (>= y menu.y)
                              (< x (+ menu.x menu.width))
                              (< y (+ menu.y (* (# menu.buttons)
                                                (+ font-size 8))))))
    (when (and input.digital input.active)
      (set mouse-pressed true))
    (when (and input.digital (not input.active))
      (set mouse-pressed nil))
    (when (and mouse-pressed mouse-on-menu)
      (local selected-last menu.selected)
      (set menu.selected (math.floor (+ 1 (/ (- y menu.y) 
                                             (+ font-size 8)))))
      (when (not= menu.selected selected-last)
        (menu-rebuild)))
    (if 
      (and (not mouse-on-menu) input.digital input.active)
      (menu-delete)

      (and mouse-on-menu input.digital (not input.active))
      (do (local fun (. menu.buttons menu.selected :fn))
          (menu-delete)
          (fun)))))
          
(fn _G.frame-handle-mouse [input]
  (local window selected)
  (when (and window window.inited)
    (when (and input.digital input.active)
      (set window.released nil))
    (when (and input.digital (not input.active))
      (set window.dragging nil)
      (when window.in-resize
        (resize-finish window))
      (set window.in-resize nil)
      (when window.pressed
        (local clicked (= window.pressed window.released))
        (set window.pressed nil)
        (window-decorate window)
        (when clicked
          (case window.released
            :menu-button
            (make-window-menu window.active-vid)
            :maximize-button
            (window-maximize window)
            :iconify-button
            (window-minimize window)
            :close-button
            (segment-delete window.active-vid)))))
    (when (and window.dragging window.pressed input.analog)
      (local (x y) (mouse_xy))
      (case window.dragging
        :title
        (window-move window
                     (+ x window.click-offset.x)
                     (+ y window.click-offset.y))
        :bottom-right-corner
        (resize-start window
                      window.x
                      window.y
                      (+ window.drag-start.w (- x window.drag-start.x))
                      (+ window.drag-start.h (- y window.drag-start.y)))
        :right-border
        (resize-start window
                      window.x
                      window.y
                      (+ window.drag-start.w (- x window.drag-start.x))
                      window.h)
        :bottom-border
        (resize-start window
                      window.x
                      window.y
                      window.w
                      (+ window.drag-start.h (- y window.drag-start.y)))
        :left-border
        (resize-start window
                      x
                      window.y
                      (+ window.drag-start.w (- window.drag-start.x x))
                      window.h)
        :bottom-left-corner
        (resize-start window
                      x
                      window.y
                      (+ window.drag-start.w (- window.drag-start.x x))
                      (+ window.drag-start.h (- y window.drag-start.y)))))))

(var joystick-x nil)
(var joystick-y nil)

(fn emulate-mouse [input]
  (when (and input.touch (not input.active))
    (set joystick-x nil)
    (set joystick-y nil))
  (when (and input.analog input.samples)
    (var rel 0)
    (when (= input.subid 0)
      (set rel (- (. input :samples 1) (or joystick-x (. input :samples 1))))
      (set joystick-x (. input :samples 1)))
    (when (= input.subid 1)
      (set rel (- (. input :samples 1) (or joystick-y (. input :samples 1))))
      (set joystick-y (. input :samples 1)))
    (set input.samples [(/ rel 4)])
    (set input.relative true)
    (set input.source :mouse)
    (set input.mouse true))
  (when (and input.digital (= input.source :joystick) (= input.subid 1))
    (set input.source :mouse)
    (set input.mouse true)))

(fn _G.hotkey [input]
  (when input.translated
    (local mod (decode_modifiers input.modifiers ""))
    (local key (keyboard.tolabel input.keysym))
    (if
      (and menu (= key :DOWN) input.active)
      (do (set menu.selected (if (= menu.selected (# menu.buttons))
                               1
                               (+ menu.selected 1)))
          (say (.. (. menu.buttons menu.selected :name)
                   " "
                   ( or (. menu.buttons menu.selected :key) "")))
          (menu-rebuild)
          true)
          
      (and menu (= key :UP) input.active)
      (do (set menu.selected (if (= menu.selected 1)
                               (# menu.buttons)
                               (- menu.selected 1)))
          (say (.. (. menu.buttons menu.selected :name)
                   " "
                   ( or (. menu.buttons menu.selected :key) "")))
          (menu-rebuild)
          true)
      
      (and menu (= key :RETURN) input.active)
      (do (local fun (. menu.buttons menu.selected :fn))
          (menu-delete)
          (fun)
          true)

      (and menu (= key (string.upper alt-key)))
      (do (when (not input.active)
            (menu-delete))
          true)
      
      (and menu input.active)
      (do (var fun nil)
          (each [_ btn (ipairs menu.buttons)]
            (when (= key btn.key)
              (set fun btn.fn)))
          (menu-delete)
          (if fun (fun))
          true)

      menu ; ignore all other keys when menu is active
      true

      (and overlay (= key :RETURN) input.active)
      (do (local fun overlay.fun)
          (local input overlay.input)
          (overlay-delete)
          (when (and fun input)
            (fun input))
          true)

      (and overlay input.active)
      (do (if
            (or (not overlay.input)
                (= key :ESCAPE)
                (and (= mod win-key) (= key :BACKQUOTE)))
            (overlay-delete)
            (= key :BACKSPACE)
            (when (> (# overlay.input) 0)
              (set overlay.input (string.sub overlay.input
                                             1
                                             (- (# overlay.input) 1))))
            :else
            (set overlay.input (.. overlay.input input.utf8)))
          (when input.utf8
            (say input.utf8))
          (overlay-rebuild)
          true)

      overlay ; ignore all other keys when overlay is active
      true

      (and (= key (string.upper alt-key))
           (not input.active))
      (do (when (and (= last-key (string.upper alt-key))
                     selected)
            (make-window-menu selected.active-vid))
          (when switch-running
            (window-select (. stack switch-current)))
          (set alt-pressed false)
          (when selected
            (set selected.dragging nil))
          true)

      (and (or (= key :PRINT) (= key :F12))
           input.active)
      (do (save_screenshot "snap.png")
          (say "snapshot")
          false)

      (and (= mod :lctrl) (= key :v) input.active selected)
      (do (clipboard-paste selected.active-vid clipboard-last)
          false)
          
      (and (= mod alt-key) (= key :F4) input.active selected)
      (do (segment-delete selected.active-vid)
          true)
          
      (and (= mod alt-key) (= key :F7) input.active selected)
      (do (target_alloc selected.active-vid
                        (make-segment-event-handler selected.primary-id)
                        :debug
                        true)
          true)

      (and (= mod alt-key) (= key :TAB) input.active)
      (do (window-switch)
          true)

      (and (= mod alt-key) (= key :BACKQUOTE) input.active selected)
      (do (segment-switch)
          true)

      (and (= mod alt-key) (= key :UP) input.active selected selected.inited)
      (do (window-move selected selected.x (- selected.y 16))
          true)

      (and (= mod alt-key) (= key :DOWN) input.active selected selected.inited)
      (do (window-move selected selected.x (+ selected.y 16))
          true)    

      (and (= mod alt-key) (= key :LEFT) input.active selected selected.inited)
      (do (window-move selected (- selected.x 16) selected.y)
          true)    

      (and (= mod alt-key) (= key :RIGHT) input.active selected selected.inited)
      (do (window-move selected (+ selected.x 16) selected.y)
          true)
      
      (= key (string.upper alt-key))
      (do (set alt-pressed input.active)
          true)

      (and (= key (string.upper win-key))
           (not input.active))
      (do (when (= last-key (string.upper win-key))
            (make-main-menu))
          true)
          
      (and (= mod win-key) (= key :BACKQUOTE) input.active)
      (do (make-arcan-cmd-overlay)
          true)

      (and (= mod win-key) (= key :RETURN) input.active)
      (do (launch-app :terminal)
          true)

      (= key (string.upper win-key))
      (do (set win-pressed input.active)
          true))))

(fn _G.a95_input [input]
  (when (or (= input.source :joystick) input.touch)
    (emulate-mouse input))
  ;(print (fennel.view input))
  (when input.mouse
    (mouse_iotbl_input input)
    (frame-handle-mouse input)
    (menu-handle-mouse input)
    (panel-handle-mouse input)
    (when input.digital
      (set last-key :mouse)
      (when overlay
        (overlay-delete))))
  (when input.translated
    (keyboard:patch input)
    (when (and (not (hotkey input))
               selected
               (valid_vid selected.active-vid))
      (target_input selected.active-vid input))
    (set last-key (keyboard.tolabel input.keysym))))

(fn _G.a95_clock_pulse []
  (mouse_tick 1)
  (keyboard:tick))

; Init

(fn _G.a95 []
  (set keyboard ((system_load :builtin/keyboard.lua)))
  ((system_load :builtin/table.lua))
  ((system_load :builtin/mouse.lua))

  (mouse_setup (load_image "cursor.png") 
               {:layer 65535
                :pickdepth 1
                :cachepick true
                :hidden false})

  (set menu-icon (load_image "menu-icon.png"))

  (config-load)

  (local modes (video_displaymodes 0))
  (video_displaymodes 0 (. modes 1 :modeid))

  ;(map_video_display 0 1 HINT_PRIMARY)
  (rendertarget_reconfigure WORLDID 38.4 38.4)

  (local thm (fennel.dofile "themes/redmond/theme.fnl" 
                            {:allowedGlobals false :correlate true}))
  (set (. themes :redmond) thm)
  (local thm (fennel.dofile "themes/microGUI/theme.fnl" 
                            {:allowedGlobals false :correlate true}))
  (set (. themes :microGUI) thm)
  (local thm (fennel.dofile "themes/CleanBig/theme.fnl" 
                            {:allowedGlobals false :correlate true}))
  (set (. themes :CleanBig) thm)

  (panel-rebuild))

