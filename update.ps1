$SourceFile = "[full path to source file].mrk"
$DestinationFile = "[full path to destination file].mrk"
$PrivateNote = '$xGeneric Note about private data'

$reader = New-Object -TypeName System.IO.StreamReader -ArgumentList $SourceFile
$writer = New-Object -TypeName System.IO.StreamWriter -ArgumentList $DestinationFile

$bLDR = [bool]$false
$isMonograph = [bool] $true
$SerialList = New-Object System.Collections.Generic.List[string]
$bfound876 = [bool]$false
$counter = 1
$separator = '$'
$options = [System.StringSplitOptions]::None
while (($current_line =$reader.ReadLine()) -ne $null)
{
	
	if ($current_line.Trim().Length -eq 0) {
		if ($bLDR -eq [bool]$true) {
			if ($isMonograph -eq [bool]$false -And $SerialList.Count -gt 0) {
				#need to generate some 876 lines
				foreach ($l in $SerialList) {
					$tmp_string = [string]$l
					$newline = "=876  \\" + '$' + $tmp_string + $PrivateNote + '$pmpb' +  ([string]$counter).PadLeft(13,'0')
					$writer.WriteLine($newline)
					$counter = $counter + 1
				}
			}

			if ($bfound876 -eq [bool]$false) {
				$newline = "=876  \\" +  $PrivateNote + '$pmb' + ([string]$counter).PadLeft(13,'0')
				$writer.WriteLine($newline)
				$counter = $counter + 1
			}
			$writer.WriteLine($current_line)
		}

		$tmp_string = ""
		$SerialList.Clear();
		$bfound = [bool]$false
		$isMonograph = [bool]$true
		$bfound876 = [bool]$false
		$str_8 = ""
		$bLDR = [bool]$false
		continue
		
	}		
	
	if (($current_line.Contains("=LDR") -eq [bool]$true) -or 
		($current_line.Contains("=000") -eq [bool]$true)) {
		$bLDR = [bool]$true
	}
	if ($current_line.Contains("=866")) {
		#per the provided information -- this doesn't need processing
		$isMonograph = [bool]$true

	} elseif ($current_line.Contains("=863")) {
		
		$isMonograph = [bool]$false
		$arr = $current_line.Split($separator, $options)
		foreach ($l in $arr) {
			$tmp_string = [string]$l			
			if ($tmp_string.StartsWith("8")) {
				$SerialList.Add($tmp_string)
			}
		}
	} elseif ($current_line.Contains("=876")) {
		$bfound876 = [bool]$true
	}



	if ($isMonograph -eq [bool]$true) {
		#this should be a monograph -- just process the data
		if ($current_line.Contains("=876")) {
			if (!$current_line.Contains('$p')) {
				$writer.WriteLine($current_line + '$pmpb' + ([string]$counter).PadLeft(13,'0'))
				$counter = $counter + 1
			} else {
				$writer.WriteLine($current_line)
			}    
		} else {
			$writer.WriteLine($current_line)
		}
	}  else {
		# this isn't a monograph -- check the 863 buffer for the $8 data
		# and if not present -- create one.  This may result in 
		# $8's being out of order, but that shouldn't honestly matter
		if ($current_line.Contains("=876")) {
			#pull the $8 [this script only will create pairs if the $8 is in the
			#863 -- if its not there, you have other issues]
			$arr = $current_line.Split($separator, $options)
			$bfound = [bool]$false
			$str_8 = ""
			foreach ($l in $arr) {
				$tmp_string = [string]$l					
				if ($tmp_string.StartsWith("8")) {
					if (!$SerialList.Contains($tmp_string)) {						
						#We need to create a new 876						
						$str_8 = $tmp_string
						$bfound = [bool]$false
						break
					} else {
						$bfound = [bool]$true						
						$index = $SerialList.IndexOf($tmp_string)
						$SerialList.RemoveAt($index)
					}
				}
			}

			if ($bfound -eq [bool]$true) {
				if (!$current_line.Contains('$p')) {								
					$writer.WriteLine($current_line + '$pmpb' + ([string]$counter).PadLeft(13,'0'))
					$counter = $counter + 1
				} else {
					$writer.WriteLine($current_line)
				}
			} else {
				$current_line = $current_line.Substring(0,8) + '$' + $str_8 + $current_line.Substring(8) + $PrivateNote + '$pmpb' +  ([string]$counter).PadLeft(13,'0')
				$writer.WriteLine($current_line)
				$counter = $counter + 1
			}    
		} else {
			$writer.WriteLine($current_line)
		} 
	}
}
$reader.Close()
$writer.Close()
