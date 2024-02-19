
# Variáveis
$pasta_origem="C:\Users\user\Projetos\backup_web.config\origem" 
$pasta_backup="C:\Users\user\Projetos\backup_web.config\backup" 
$pasta_raiz= "C:\Users\user\Projetos\backup_web.config\" # Onde serão gravados os arquivos compactados.
$data=Get-Date -Format "yyyyMMdd_HHmmss"
$arquivo_zip = $pasta_raiz + $data + "-TST-webconfig.7z" # Nome do arquivo compactado.
$7zip = "C:\Program Files\7-Zip\7z.exe" # Executável do 7zip.
$argumentos = "a -t7z -mx9  $arquivo_zip $pasta_backup" 
$quantidade_versões = 5 # Quantidades de versões compactadas que ficarão armazenadas.


function Backup {
    # Varrer a pasta recursivamente
    Get-ChildItem -Path $pasta_origem -Recurse -Filter "web.config" | ForEach-Object {
        # Caminho relativo do web.config em relação à pasta de origem
        $caminho_relativo = $_.FullName.Substring($pasta_origem.Length + 1)
        
        # Caminho completo na pasta de backup
        $caminho_destino = Join-Path -Path $pasta_backup -ChildPath $caminho_relativo
        
        # Criar estrutura de pasta
        $pasta_destino = Split-Path -Path $caminho_destino -Parent
        if (-not (Test-Path -Path $pasta_destino -PathType Container)) {
            New-Item -Path $pasta_destino -ItemType Directory -Force
        }
        
        # Backup do web.config
        Copy-Item -Path $_.FullName -Destination $caminho_destino -Force
        Write-Host "Copiado $($_.FullName) para $caminho_destino"
    }
}


function Restore {

    # Prompt de confirmação
    $confirmacao = Read-Host "Tem certeza de que deseja restaurar os backups? (S/N)"
    
    
    if ($confirmacao -ne 'S') {
        Write-Host "Operacao de restauracao cancelada." -ForegroundColor Red
        return
    }

    # Varrer a pasta de backup recursivamente
    Get-ChildItem -Path $pasta_backup -Recurse -Filter "web.config" | ForEach-Object {
        # Caminho relativo do web.config em relação à pasta de backup
        $caminho_relativo = $_.FullName.Substring($pasta_backup.Length + 1)
        
        # Caminho completo no diretório de destino
        $caminho_destino = Join-Path -Path $pasta_origem -ChildPath $caminho_relativo
        
        # Criar estrutura de pasta
        $pasta_destino_webconfig = Split-Path -Path $caminho_destino -Parent
        if (-not (Test-Path -Path $pasta_destino_webconfig -PathType Container)) {
            New-Item -Path $pasta_destino_webconfig -ItemType Directory -Force
        }
        
        # Restaurar o web.config
        Copy-Item -Path $_.FullName -Destination $caminho_destino -Force
        Write-Host "Restaurado $($_.FullName) para $caminho_destino" -ForegroundColor Green
    }
}


function Check {

    # Variável controle se teve alterações
    $alterado = $false
    # Obtém a lista de arquivos na pasta de origem
    $arquivos_origem = Get-ChildItem -Path $pasta_origem -Recurse -Filter "web.config" -File

    foreach ($arquivo_origem in $arquivos_origem) {
        # Caminho relativo do arquivo em relação à pasta de origem
        $caminho_relativo = $arquivo_origem.FullName.Substring($pasta_origem.Length + 1)
        
        # Caminho completo no diretório de backup
        $caminho_backup = Join-Path -Path $pasta_backup -ChildPath $caminho_relativo
        
        if (Test-Path -Path $caminho_backup) {
            # Se o arquivo existe no backup, compara os hashes
            $hash_origem = Get-FileHash -Path $arquivo_origem.FullName -Algorithm SHA256 | Select-Object -ExpandProperty Hash
            $hash_backup = Get-FileHash -Path $caminho_backup -Algorithm SHA256 | Select-Object -ExpandProperty Hash
        
            if ($hash_origem -ne $hash_backup) {
                Write-Host "O arquivo $caminho_relativo foi modificado desde o ultimo backup." -ForegroundColor Red
                $alterado = $true
            }        
        } else {
            # Se o arquivo não existe no backup, foi criado após o último backup
            Write-Host "O arquivo $caminho_relativo foi criado apos o ultimo backup." -ForegroundColor Yellow
            $alterado = $true
        
        }
    }
    # Não foi alterado nada?
    if ($alterado -eq $false) {
        Write-Host "Nao ouve alteracoes nos arquivos desde o ultimo backup." -ForegroundColor Yellow
    }
}


function Compact {
    Start-Process -FilePath $7zip -ArgumentList $argumentos -Wait
}


function Rotate {


    # Obter todos os arquivos no diretório e ordená-los pela data de modificação (do mais antigo para o mais recente)
    $arquivos = Get-ChildItem -Path $pasta_raiz -Filter '*.7z' | Sort-Object LastWriteTime

    # Verificar se há mais arquivos do que a quantidade desejada para manter
    if ($arquivos.Count -gt $quantidade_versões) {
        # Calcular quantos arquivos precisam ser removidos
        $quantidade_a_remover = $arquivos.Count - $quantidade_versões
        
        # Remover os arquivos mais antigos
        for ($i = 0; $i -lt $quantidade_a_remover; $i++) {
            $arquivos[$i] | Remove-Item -Force
        }
    }
}


function Menu {
    Clear-Host
    Write-Host "=== Backup de Web.Configs ===`n"
    Write-Host "Pasta de Origem: $pasta_origem`n" -ForegroundColor Red
    Write-Host "Pasta de Backup: $pasta_backup`n" -ForegroundColor Green
    Write-Host "Selecione o numero correspondente a opcao que voce deseja:"
    Write-Host "1 - Realizar Backup dos web.configs"
    Write-Host "2 - Verificar web.configs que foram alterados desde o ultimo backup"
    Write-Host "3 - Restaurar o backup dos web.configs"
}

# Execução

# Se tiver um argumento 'auto' fará o backup sem exibir o menu.
if ($args -eq'auto'){
    Backup
    Compact
    Rotate
    exit
}

# Menu de opções
$loop = $true

while ($loop) {
    Start-Sleep -Seconds 1
    Menu
    $choice = Read-Host "Digite o numero da opcao desejada (ou 'Q' para sair)"

    switch ($choice) {
        '1' { Backup; Compact; Rotate; $loop = $false; break }
        '2' { Check; $loop = $false; break }
        '3' { Restore; $loop = $false; break }

        'Q' { $loop = $false; break }
        default { Write-Host "`nOpcao invalida. Tente novamente." -ForegroundColor Red}
    }
}