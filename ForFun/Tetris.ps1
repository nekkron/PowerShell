# https://github.com/michaelvdnest/powershell-tetris

$screenWidth = 80
$screenHeight = 30
$tetrominos = @()
$fieldWidth = 12
$fieldHeight = 18
$field = , 0 * ($fieldWidth * $fieldHeight) #Create play field buffer

$screen = $null

function Rotate($x, $y, $r) {
    
    $i = 0
    $w = 4
    switch ($r % 4) {
        
        0 {      # 0 degrees			# 0  1  2  3   .  .  X  .  
		    $i = $y * $w + $x			# 4  5  6  7   .  .  X  .
		}          						# 8  9 10 11   .  .  X  .
                                    	#12 13 14 15   .  .  X  .

	    1 {     # 90 degrees			#12  8  4  0   .  .  .  .  
		    $i = 12 + $y - ($x * $w)	#13  9  5  1   .  .  .  .  
		}         						#14 10  6  2   X  X  X  X  
         								#15 11  7  3   .  .  .  .  

	    2 {    # 180 degrees			#15 14 13 12   .  X  .  .
		    $i = 15 - ($y * $w) - $x	#11 10  9  8   .  X  .  .
		}               				# 7  6  5  4   .  X  .  .
	        							# 3  2  1  0   .  X  .  .

	    3 {    # 270 degrees			# 3  7 11 15   .  .  .  .
		    $i = 3 - $y + ($x * $w) 	# 2  6 10 14   X  X  X  X
		}         						# 1  5  9 13   .  .  .  .
	        							# 0  4  8 12   .  .  .  .
    }

    $i
}

function DoesPieceFit($tetromino, $rotation, $posX, $posY) {
    
     #All Field cells >0 are occupied

    foreach ($x in 0..3) {
        foreach ($y in 0..3) {
            
            # Get index into piece
            $i = Rotate $x $y $rotation

            # Get index into field
            $fi = ($posY + $y) * $fieldWidth + ($posX + $x);
            
            # Check that test is in bounds. Note out of bounds does
			# not necessarily mean a fail, as the long vertical piece
			# can have cells that lie outside the boundary, so we'll
			# just ignore them
			if (($posX + $x -ge 0) -and ($posX + $x -le $fieldWidth)) {
				if (($posY + $y -ge 0) -and ($posY + $y -le $fieldHeight)) {
					# In Bounds so do collision check
                    if (($tetrominos[$tetromino][$i] -ne '.') -and ($field[$fi] -ne 0)) {
                        return $false; # fail on first hit
                    }
				}
			}
              
        }
    }

    return $true
}

    $pshost = Get-Host
    $isConsole = ($pshost.Name -eq 'ConsoleHost') 

    if (-not $isConsole) {
        Start-Process powershell $PSCommandPath
    } else {
        # Create screen
        $pswindow = $pshost.UI.RawUI

        if ($isConsole) {
            $newsize = $pswindow.WindowSize
            $newsize.Width = $screenWidth
            $newsize.Height = $screenHeight
            $pswindow.WindowSize = $newsize
            $pswindow.Buffersize = $newsize    
        
            # Hide cursor
            $pswindow.CursorSize = 0
        }

        # Create screen buffer
        $screen = (0..($screenHeight-5)) | % { 
            $line = New-Object System.Text.StringBuilder($screenWidth,$screenWidth)
            $line.Append(' ', $screenWidth)
        }
        
        # Create play field buffer
        $h = $fieldHeight - 1
        $w = $fieldWidth - 1
        foreach ($y in  0..$h) {
            foreach ($x in  0..$w) {
                if ($x -in (0, $w) -or ($y -eq $h)) {
                    $field[$y * $fieldWidth + $x ] = 9
                }
            }
        }
        
        #  Create assets
        $tetrominos += ".XX." +
                       ".XX." +
                       "...." +
                       "...."

        
        $tetrominos+= "...." +
                      "XXXX" +
                      "...." +
                      "...."

        $tetrominos+= ".X.." +
                      "XXX." +
                      "...." +
                      "...."
        
        $tetrominos += "..X." +
                       "XXX." +
                       "...." +
                       "...."

        $tetrominos += ".X.." +
                       ".XXX" +
                       "...." +
                       "...."

        $tetrominos+= ".XX." +
                      "XX.." +
                      "...." +
                      "...."

        $tetrominos+= ".XX." +
                      "..XX" +
                      "...." +
                      "...."
        
        # Game logic
        $currentPiece = 2 #(Get-Random -Maximum ($tetrominos.Length-1))
        $currentRotation = 0
        $currentY = 0
        $currentX = ($fieldWidth / 2) - 2
        $rotationHold = $false
        $speed = 20
        $speedCount = 0
        $forceDown = $false
        $quit = $false
        $gameOver = $false
        $lines = @()
        $score = 0
        $pieceCount = 0
                    
        while (-not $quit -and -not $gameOver) {
            
            $cursor = $Host.UI.RawUI.CursorPosition
            $cursor.x = 0
            $cursor.y = $screenHeight -2
            $pshost.UI.RawUI.CursorPosition = $cursor #reposition cursor

            # GAME TIMING
            Start-Sleep -Milliseconds 50
            $speedCount++
            $forceDown = ($speedCount -eq $speed);

            # INPUT
            $key = $null
            if ($host.ui.RawUI.KeyAvailable) {
                # ReadKey only returns with IncludeKeyUp and we want to handle KeyDown for arrow keys.
                $key = $pshost.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown,IncludeKeyUp")
                $pswindow.FlushInputBuffer()
            }

            if ($key) {
                switch ($key.Character) {
                    0 {} # Do nothing if not a character

                    'q' { $quit = $true }
                }

                # Only handle key down events. Using both will duplicate the key event.
                if ($key.KeyDown) {

                    $v = ""
                    switch ($key.VirtualKeyCode) {
                        37 { $v = "l" 
                            if (DoesPieceFit $currentPiece $currentRotation ($currentX - 1) $currentY) {
                                $currentX--
                            }    
                        }
                        38 { $v = "u" 
                            if (DoesPieceFit $currentPiece ($currentRotation + 1) $currentX $currentY) {
                                $rotationHold = $false
                                $currentRotation++
                            } else {
                                $rotationHold = $true
                            }
                        }
                        39 { $v = "r" 
                            if (DoesPieceFit $currentPiece $currentRotation ($currentX + 1) $currentY) {
                                $currentX++
                            }    
                        }
                        40 { $v = "d" 
                            if (DoesPieceFit $currentPiece $currentRotation $currentX ($currentY + 1)) {
                                $currentY++
                            }
                        }
                    }
                }
            }
            
            
            # LOGIC

            # Clear lines
            $lines | % {
                
                $v = $_

                for ($x=1; $x -lt ($fieldWidth - 1); $x++) {
                    for ($y = $v; $y -gt 0; $y--) {
                        $field[$y * $fieldWidth + $x] = $field[($y - 1) * $fieldWidth + $x]
                    }
                    $field[$x] = 0
                }
            }
            $lines = @()
            
            if ($forceDown) {
                
                $speedCount = 0
                $pieceCount++
                if ($pieceCount % 50 -eq 0) {
				    if ($speed -ge 10) {
                        $speed--
                    }
                }

                if (DoesPieceFit $currentPiece $currentRotation $currentX ($currentY + 1)) {
                    $currentY++
                } else {
                    # Lock the piece in place
                    foreach ($x in 0..3) {
                        foreach ($y in 0..3) {
                            if ($tetrominos[$currentPiece][(Rotate $x $y $currentRotation)] -ne '.') {
                                $field[($currentY + $y) * $fieldWidth + ($currentX + $x)] = $currentPiece + 1
                            }
                        }
                    }

                    # Check for lines
                    foreach ($y in 0..3) {
                        if($currentY + $y -lt $fieldHeight - 1) {
                            
                            $line = $true
                            for ($x=1; $x -lt ($fieldWidth - 1); $x++) {
                                if ($field[($currentY + $y) * $fieldWidth + $x] -eq 0) {
                                    $line = $false
                                    break
                                }
                            }

                            if ($line) {
                                # Set line to =
                                for ($x=1; $x -lt ($fieldWidth - 1); $x++) {
                                    $field[($currentY + $y) * $fieldWidth + $x] = 8
                                }
                                
                                $lines += ($currentY + $y)
                            }
                        }
                    }

                    # score
                    $score += 25; 
                    if($lines.Count -gt 0) { $score += (1 -shl $lines.Count) * 100 }

                    # Pick New Piece
				    $currentX = ($fieldWidth / 2) - 2
				    $currentY = 0
				    $currentRotation = 0
				    $currentPiece = (Get-Random -Maximum ($tetrominos.Length-1))

                    # If piece does not fit straight away, game over!
				    $gameOver = (-not (DoesPieceFit $currentPiece $currentRotation $currentX $currentY))
                }
            }


            # RENDERING
            
            # Draw field
            for ($x=0; $x -lt $fieldWidth; $x++) {
                for ($y=0; $y -lt $fieldHeight; $y++) {
                    $screen[$y + 2][$x + 2] = " ABCDEFG=#"[$field[$y*$fieldWidth + $x]]
                }
            }
            
            # Draw current piece
            foreach ($x in 0..3) {
                foreach ($y in 0..3) {
                    if ($tetrominos[$currentPiece][(Rotate $x $y $currentRotation)] -ne '.') {
                        $screen[$currentY + $y + 2][$currentX + $x + 2] = [char]($currentPiece + 65)        
                    }
                }
            }

            # Draw score
            $score_text = "SCORE: $score"
            $screen[2].Remove($fieldWidth + 6, $score_text.Length) | Out-Null
            $screen[2].Insert($fieldWidth + 6, $score_text) | Out-Null
            
            
            # Display Screen
            if ($isConsole) {
                $origin = $pswindow.WindowPosition
                $screen | % {
                    $row = $pswindow.NewBufferCellArray($_, "white", "black")
                    $pswindow.SetBufferContents($origin, $row)
                    $origin.Y++
                }
            }

            if ($lines.Count -gt 0) {
                Start-Sleep -Milliseconds 400
            }

        }
        
        Clear-Host
        if ($gameOver) { Write-Host "Game over!" }
        Read-Host 
    }