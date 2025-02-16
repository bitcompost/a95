;; based on microGUI theme from sawfish WM

(local frame
  [{:background [(load_image "themes/microGUI/top_left_inactive.png")
                 (load_image "themes/microGUI/top_left.png")]
    :left-edge -6
    :top-edge -19
    :type :top-left-corner}

   ;; top blue
   {:background [(load_image "themes/microGUI/top_blue_inactive.png")
                 (load_image "themes/microGUI/top_blue.png")]
    :foreground :ffffff
    :text (fn [segment] segment.id)
    :text-x 4
    :text-y 0
    :top-edge -19
    :left-edge 19
    :width (fn [segment] (/ segment.window.w 2))
    :type :title}
   
   ;; menu button
   {:background [(load_image "themes/microGUI/menu_normal.png")
                 (load_image "themes/microGUI/menu_active.png")
                 (load_image "themes/microGUI/menu_clicked.png")]
    :top-edge -19
    :left-edge 0
    :type :menu-button}
    
   ;; top curves
   {:background [(load_image "themes/microGUI/top_curves_inactive.png")
                 (load_image "themes/microGUI/top_curves.png")]
    :left-edge (fn [segment] (/ segment.window.w 2))
    :top-edge -19
    :type :title}
   
   ;; top grey
   {:background (load_image "themes/microGUI/top_grey.png")
    :top-edge -19
    :left-edge (fn [segment] (+ 12 (/ segment.window.w 2)))
    :right-edge 51
    :type :title}
   
   ;; iconify button
   {:background [(load_image "themes/microGUI/minimize_normal.png")
                 (load_image "themes/microGUI/minimize_active.png")
                 (load_image "themes/microGUI/minimize_clicked.png")]
    :right-edge 35
    :top-edge -19
    :type :iconify-button}
   
   ;; maximize button
   {:background [(load_image "themes/microGUI/maximize_normal.png")
                 (load_image "themes/microGUI/maximize_active.png")
                 (load_image "themes/microGUI/maximize_clicked.png")]
    :right-edge 18
    :top-edge -19
    :type :maximize-button}
   
   ;; close button
   {:background [(load_image "themes/microGUI/close_normal.png")
                 (load_image "themes/microGUI/close_active.png")
                 (load_image "themes/microGUI/close_clicked.png")]
    :right-edge 1
    :top-edge -19
    :type :close-button}
   
   ;; top-right corner
   {:background (load_image "themes/microGUI/top_right.png")
    :right-edge -6
    :top-edge -19
    :type :top-right-corner}
   
   ;; right border
   {:background (load_image "themes/microGUI/right.png")
    :right-edge -6
    :top-edge 0
    :bottom-edge 0
    :type :right-border}
   
   ;; bottom-right corner
   {:background (load_image "themes/microGUI/br.png")
    :right-edge -6
    :bottom-edge -6
    :type :bottom-right-corner}
   
   ;; bottom border
   {:background (load_image "themes/microGUI/bottom.png")
    :left-edge 0
    :right-edge 0
    :bottom-edge -6
    :type :bottom-border}
   
   ;; bottom-left corner
   {:background (load_image "themes/microGUI/bl.png")
    :left-edge -6
    :bottom-edge -6
    :type :bottom-left-corner}
   
   ;; left border
   {:background (load_image "themes/microGUI/left.png")
    :left-edge -6
    :top-edge 8
    :bottom-edge 0
    :type :left-border}])

{:name :MicroGUI :frame frame}
