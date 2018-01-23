# Cria novo projeto
project-new --named rhforum --version 1.0 --stack JAVA_EE_7 --type wildfly-swarm --top-level-package com.redhat.rhforum

# Configura git
git-setup
#gitignore-setup
gitignore-create --templates Maven

# Criar entidade JPA
jpa-new-entity --named Cliente
jpa-new-field --named nome
jpa-new-field --named sobrenome

# Adiciona Bean Validation
wildfly-swarm-add-fraction --fractions bean-validation
constraint-add --constraint NotNull --on-property nome
constraint-add --constraint NotNull --on-property sobrenome

# Adiciona datasource
wildfly-swarm-add-fraction --fractions datasources
jdbc-add-dependency --db-type H2 --version 1.4.196

# Gera endpoint REST a partir da entidade JPA
rest-generate-endpoints-from-entities --targets com.redhat.rhforum.model.Cliente

# Adiciona swagger
wildfly-swarm-add-fraction --fractions swagger
swagger-setup
swagger-generate

# Adiciona testes
wildfly-swarm-new-test --named ClienteTest

# Adiciona contexto de health check
wildfly-swarm-add-fraction --fractions monitor

# Gera classe main
wildfly-swarm-detect-fractions --depend
wildfly-swarm-new-main-class

# Setup fabric8-maven-plugin
fabric8-setup
