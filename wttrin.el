;;; wttrin.el --- Emacs frontend for weather web service wttr.in  -*- lexical-binding: t; -*-
;; Copyright (C) 2016 Carl X. Su

;; Author: Carl X. Su <bcbcarl@gmail.com>
;;         ono hiroko (kuanyui) <azazabc123@gmail.com>
;; Version: 0.2.0
;; Package-Requires: ((emacs "24.4") (xterm-color "1.0"))
;; Keywords: comm, weather, wttrin
;; URL: https://github.com/bcbcarl/emacs-wttrin

;;; Commentary:

;; Provides the weather information from wttr.in based on your query condition.

;;; Code:

(require 'cl-lib)
(require 'url)
(require 'xterm-color)


(defvar url-http-response-status)


(defgroup wttrin nil
  "Emacs frontend for weather web service wttr.in."
  :prefix "wttrin-"
  :group 'comm)


(defcustom wttrin-cities nil
  "Specify cities list for quick completion."
  :group 'wttrin
  :type 'list)


(defcustom wttrin-forecast-days 0
  "Forecast days."
  :group 'wttrin
  :type '(choice
          (const :tag "Only current weather" 0)
          (const :tag "Current weather + today's forecast" 1)
          (const :tag "Current weather + today's + tomorrow's forecast" 2)))


(defcustom wttrin-language "en"
  "The language of the display.
am ar af be ca da de el et fr fa hi hu ia id it lt nb nl oc pl pt-br
ro ru tr th uk vi zh-cn zh-tw (supported)
az bg bs cy cs eo es eu fi ga hi hr hy is ja jv ka kk ko ky lv mk ml
mr nl fy nn pt pt-br sk sl sr sr-lat sv sw te uz zh zu he (in progress)"
  :group 'wttrin
  :type 'string)


(defcustom wttrin-units-metric nil
  "Metric (SI) (used by default everywhere except US).(url?m)"
  :group 'wttrin
  :type 'boolean)


(defcustom wttrin-units-USCS nil
  "USCS (used by default in US).(url?u)"
  :group 'wttrin
  :type 'boolean)


(defcustom wttrin-units-wind-speed nil
  "Show wind speed in m/s.(url?M)"
  :group 'wttrin
  :type 'boolean)


(defcustom wttrin-request-extra-headers nil
  "Extra haeders that wttrin request."
  :group 'wttrin
  :type '(group cons))


(defcustom wttrin-visual-buffer-name "*wttr.in*"
  "Wttrin visual buffer name."
  :group 'wttrin
  :type 'string)

;;;; constants

(defconst wttrin-url "http://wttr.in/"
  "Wttrin url.")


(defconst wttrin-langs '("am" "ar" "af" "be" "ca" "da" "de" "el" "et" "fr" "fa" "hi" "hu" "ia" "id" "it" "lt" "nb" "nl" "oc" "pl" "pt"-"br" "ro" "ru" "tr" "th" "uk" "vi" "zh-cn" "zh-tw")
  "Wttrin supported languages")


(defun wttrin-make-request-url (&optional city)
  "Make request url by CITY."
  (concat wttrin-url city "?AF" (number-to-string wttrin-forecast-days)
          (if wttrin-units-metric "m" "")
          (if wttrin-units-USCS "u" "")
          (if wttrin-units-wind-speed "M" "")
          "&lang=" (if (cl-position wttrin-language wttrin-langs :test 'equal)
                       wttrin-language "en")))


(defun wttrin-request (url callback)
  "Handle request by URL.
CALLBACK: function of after response."
  (let ((url-request-method "GET"))
    (if wttrin-request-extra-headers
        (setq url-request-extra-headers wttrin-request-extra-headers))
    (url-retrieve url (lambda (_status)
                        (let ((inhibit-message t))
                          (message "wttrin: %s at %s" "The request is successful." (format-time-string "%T")))
                        (funcall callback)) nil 'silent)))


(defun wttrin-parse-response ()
  "Parse response result by body."
  (if (/= 200 url-http-response-status)
      (error "Internal Server Error."))
  (let ((resp-str (with-current-buffer (current-buffer)
                    (buffer-substring-no-properties (search-forward "\n\n") (point-max)))))
    (decode-coding-string resp-str 'utf-8)))


(defun wttrin-exit ()
  "Exit wttrin."
  (interactive)
  (quit-window t))


(defun wttrin-query (&optional city)
  "Query weather of CITY via wttrin, and display the result in new buffer."
  (wttrin-request (wttrin-make-request-url city)
                  (lambda ()
                    (let ((resp (wttrin-parse-response)))
                      (if (string-match "ERROR" resp)
                          (message "Cannot get weather data. Maybe you inputed a wrong city name?")

                        (with-current-buffer
                            (get-buffer-create wttrin-visual-buffer-name)
                          (let ((inhibit-read-only t))
                            (wttrin-visual-mode)
                            (erase-buffer)
                            
                            (insert (format-time-string "%G-%m-%d") "\n\n")
                            (insert (xterm-color-filter resp)))
                          (local-set-key "q" 'wttrin-exit)
                          (local-set-key "g" 'wttrin))

                        (switch-to-buffer wttrin-visual-buffer-name))))))


;;;###autoload
(defun wttrin (&optional city)
  "Display weather information that select CITY,
also input citry name to display the information,
or input emty to display the information of current location."
  (interactive (list (if wttrin-cities
                         (completing-read "City name: " wttrin-cities nil nil ""))))
  (wttrin-query city))


(define-derived-mode wttrin-visual-mode nil wttrin-visual-buffer-name 
  "Major mode for wttrin view."
  :group 'wttrin
  (buffer-disable-undo)
  
  (setq truncate-lines t
        buffer-read-only t
        show-trailing-whitespace nil
        line-spacing 0.1)
  (setq-local line-move-visual t
              view-read-only nil)
  
  (defface wttrin-buffer-local-face
    '((t :height 120))
    "wttrin-buffer-local face")
  (buffer-face-set 'wttrin-buffer-local-face)
  (run-mode-hooks))


(provide 'wttrin)

;;; wttrin.el ends here
