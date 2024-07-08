# Configuración de Infraestructura con Terraform

========================================

Este repositorio contiene la configuración de infraestructura para desplegar una instancia EC2 en AWS, configurar un servidor web Apache con PHP, un formulario HTML que envía datos a un tópico SNS, y una Lambda que envía notificaciones a Slack.

---

## Pasos para Configurar y Desplegar

### Paso 1: Inicialización de Terraform

1. **Inicializa Terraform:**
   ```bash
   terraform init
    ```

Paso 2: Configuración de Clave SSH
Configura la Clave SSH:
Asegúrate de tener una clave SSH válida en tu sistema.
Ejecuta el siguiente script para configurar y asignar los permisos adecuados:


   ```chmod +x setup_ssh.sh
./setup_ssh.sh

    ```

Paso 3: Despliegue de la Infraestructura
Aplica la Configuración de Terraform:
Despliega la infraestructura en tu cuenta de AWS utilizando Terraform:      

       ```bash
   terraform apply

    ```

Notas Adicionales
Asegúrate de tener configuradas las credenciales adecuadas de AWS en tu entorno.
Verifica y ajusta el archivo main.tf según tus necesidades específicas antes de aplicar los cambios.

Recursos Creados por Terraform
Instancia EC2: Configurada con Apache, PHP y un formulario HTML.
Grupo de Seguridad: Permite el tráfico HTTP y SSH.
Tópico SNS: Para recibir mensajes del formulario.
Lambda: Para enviar notificaciones a Slack.
