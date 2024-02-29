# backup_web.config

Realiza backups de web.configs mantendo a estrutura original de diretórios e subdiretórios.

Como utilizar


![Preview](preview.png)



Opções:

## 1 - Backup
 Fará a leitura da estrutura de arquivos dentro da pasta de origem e vai mapear todos os web.configs recursivamente.

Para cada web.config criará a pasta pai dentro da pasta de backup e copiará o web.config para lá.

Após concluída a cópia de todos os web.config criará um arquivo compactado da pasta de backup com a data e hora no nome dentro de C:\Backups.

Vai verificar a quantidade de arquivos compactados na pasta e vai manter apenas os 5 mais recentes. Os demais serão apagados.



## 2 - Verificar

Para cada web.config irá criar um hash sha256 e comparar com o web.config equivalente na pasta de backup. Informará se houve alterações, e qual o arquivo que está diferente.


## 3 - Restaurar.

Fará uma cópia de todos os web.configs no diretório de backup de volta para o diretório de origem. 

Pode ser usado para aplicar alterações dos web.configs.



## Backup Agendado

Ao executar o script informando o argumento ‘auto’ ele automaticamente iniciará a função de backup.
Pode ser configurado da seguinte forma no scheduler do windows:

executar com o usuário logado ou não

executar com os privilégios mais altos

programa: powershell.exe

argumentos: C:\Backup\backup_webconfigs_br.ps1 auto

## Login gcloud
gcloud auth activate-service-account mgt-backups-infra@migrate-ad.iam.gserviceaccount.com --key-file "migrate-ad-e247df27092d.json"
