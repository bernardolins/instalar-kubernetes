## Instalar Kubernetes através de um JSON

### Dependências

Instalar js e jsawk.

```
$ sudo apt-get install
```

### Contrato

Crie um arquivo JSON que representa seu cluster, seguindo um formato como esse:

```json
{
  "version": "v1.1.6",
  "token": "unique-cluster-id",
  "master": { 
    "hostname": "master-01",
    "ip": "172.17.0.1",
    "interface": "enp4s3"
  },
  "workers": [
    {
      "hostname": "worker01",
      "ip": "172.17.0.2",
      "interface": "enp4s3"
    },
    {
      "hostname": "worker02",
      "ip": "172.17.0.3",
      "interface": "enp4s3"
    }
  ]
}
```

**version**: Versão do kubernetes que será instalada

**token**: Token do cluster etcd

**master**: Informações sobre o master do kubernetes

**workers**: Informações sobre os workers
