## Instalar Kubernetes através de um JSON

### Quick Start 
Esse script ajuda a gerar a configuração necessária para instalar um cluster do kubernetes, baseado em arquivos de templates.

```bash
./generate-configs.sh -f example.json -d templates/ -o configs/

```

1. -f: Arquivo json com o manifesto do cluster. Veja em example.json um arquivo exemplo 

2. -d: Diretório com os templates. Veja em configs/ um exemplo de configuração

3. -o: Diretório onde será guardado o output

### Arquitetura do cluster
O cluster terá o seguinte formato:

*1 nó master*, *n nós worker*, *n nós etcd dedicados* e *n nós com o client (kubectl) dedicados, que serão usados para modificar o estado do seu cluster*

### Dependências

Instalar o jsawk.
[Instruções para o jsawk](https://github.com/micha/jsawk)

Você deve ter um interpretador de javascript instalado na sua máquina. No fedora

```bash
sudo dnf install js
```

### Contrato

Crie um arquivo JSON que representa seu cluster, seguindo um formato como esse:

```json
{
  "version": "v1.1.8",
  "token": "unique-cluster-id",
  "master": { 
    "hostname": "master01",
    "ip": "172.17.0.1",
    "interface": "enp4s3"
  },
  "workers": [
    {
      "hostname": "worker01",
      "ip": "172.17.0.2",
      "interface": "eth0"
    },
    {
      "hostname": "worker02",
      "ip": "172.17.0.3",
      "interface": "eth0"
    }
  ],
  "etcd": [
    {
      "hostname": "etcd01",
      "ip": "172.17.0.101",
      "interface": "ens3"
    },
    {
      "hostname": "etcd02",
      "ip": "172.17.0.102",
      "interface": "ens3"
    },
    {
      "hostname": "etcd03",
      "ip": "172.17.0.103", 
      "interface": "ens3"
    }
  ],
  "kubectl": [ 
    {
      "hostname": "client01",
      "ip": "172.17.0.151",
      "interface": "eth1"
    }
  ]
}
```

**version**: Versão do kubernetes que será instalada

**token**: Token do cluster etcd. Deve ser único

**master**: Informações sobre o master do kubernetes

**workers**: Informações sobre os workers

**etcd**: Informações das máquinas que formam o cluster etcd

**kubectl**: Informações das máquinas que receberão o cli do kubernetes (kubectl)
