# skuta
A very basic battery and temperature e-scooter app for Trittbrett Kalle.

* The app is intended to get quick access to the following data:
    * battery level
    * motor temperature
    * controller temperature

## Limitations

* The device mac address is hardcoded to the app since I intended it to connect directly without the need to scan for a device. 
  * If you want to use this for your own Kalle E-Scooter change the address and name set in the `_device` of the `_MainScreenState`.
  * This might also work for other Trittbrett scooters like Emma, Fritz or Paul (untested)
