<h1 align="left">Adobe Acrobat Reader DC</h1>

###

<p align="left">Custom configurations for use on shared, public computers</p>

###

<h2 align="left">What does it do?</h2>

###

<p align="left">1. Creates log file for installation process<br>2. Installs WinGet and all dependencies<br>3. Installs Adobe Acrobat Reader DC (64-bit)<br>_a. Verbose install log<br>_b. Accepts EULA for the device<br>4. Backs up existing registry<br>5. Downloads & injects custom registry keys<br>6. Allows for easy updating using winget</p>

###

<h2 align="left">I need to roll back changes to the registry!</h2>

###

<p align="left">Simplest way to do this is to delete this key and all keys below.<br>[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Adobe]<br><br>The next time Adobe Acrobat Reader DC is opened, the default keys will be automatically generated.</p>

###

<div align="left">
  <img src="https://skillicons.dev/icons?i=powershell" height="40" alt="powershell logo"  />
</div>

###
