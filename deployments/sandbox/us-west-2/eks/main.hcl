################################################################################
# EKS Module
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access  = true
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    aws-ebs-csi-driver = {}
    coredns = {}
    eks-pod-identity-agent = {}
    kube-proxy = {}
    vpc-cni = {}
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # cloudwatch
  create_cloudwatch_log_group = false
  cloudwatch_log_group_retention_in_days = 30
  cloudwatch_log_group_class  = "INFREQUENT_ACCESS"

  # kms
  create_kms_key            = false
  cluster_encryption_config = {}

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["t3.medium"]
  }

  cluster_security_group_additional_rules = {
    ingress_nodes_ephemeral_ports_tcp = {
      description                = "Node group to Cluster API ingress TCP ports 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "ingress"
      source_node_security_group = true
    }

    egress_nodes_ephemeral_ports_tcp = {
      description                = "Node group to cluster API egress TCP ports 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }

  # Enable node to node communication
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node ingress all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }

    egress_self_all = {
      description = "Node to node egress all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      self        = true
    }

    # Control plane to nodes
    ingress_cluster_to_node_all_traffic = {
      description                   = "Cluster API to node group all traffic"
      protocol                      = "-1"
      from_port                     = 0
      to_port                       = 0
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }

  eks_managed_node_groups = {
    # core infra - cicd
    core = {
      name        = "core-node-group"
      description = "Core managed node group launch template"

      subnet_ids = module.vpc.private_subnets

      min_size     = 1
      max_size     = 2
      desired_size = 1

      ami_type       = "AL2_x86_64"
      instance_types = ["t3.large"]
      capacity_type  = "SPOT"

      labels = {
        role = "core"
      }

      ebs_optimized           = true
      disable_api_termination = false
      enable_monitoring       = false

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size = 30
            volume_type = "gp3"
            encrypted   = false
            #kms_key_id            = module.ebs_kms_key.key_arn
            delete_on_termination = true
          }
        }
      }

      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
        instance_metadata_tags      = "disabled"
      }

      create_iam_role          = true
      iam_role_name            = "core-managed-node-group-role"
      iam_role_use_name_prefix = false
      iam_role_description     = "core Managed node group role"
      iam_role_tags = {
        Purpose = "core-managed-node-group-role-tag"
      }
      iam_role_additional_policies = {
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
        AmazonSSMManagedInstanceCore       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }

      launch_template_tags = {
        # enable discovery of autoscaling groups by cluster-autoscaler
        "k8s.io/cluster-autoscaler/enabled" : true,
        "k8s.io/cluster-autoscaler/${local.name}" : "owned",
      }

      tags = {
        ExtraTag = "core-node"
      }
    }
  }

  access_entries = {
    cert-manager = {
      principal_arn = aws_iam_role.cert_manager.arn
      policy_associations = {
        admin_policy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }

    external-dns = {
      principal_arn = aws_iam_role.external_dns.arn
      policy_associations = {
        admin_policy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }

    external-secrets = {
      principal_arn = aws_iam_role.external_secrets.arn
      policy_associations = {
        admin_policy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
}

## automation
#resource "aws_iam_role" "this" {
#  for_each = toset(["argocd", "jenkins", "alertmanager", "kubestatemetrics", "nodexporter", "grafana", "prometheus", "prometheusoperator"])
#
#  name = each.key
#
#  assume_role_policy = jsonencode({
#    Version = "2012-10-17"
#    Statement = [
#      {
#        Action = "sts:AssumeRole"
#        Effect = "Allow"
#        Sid    = "Example"
#        Principal = {
#          Service = "ec2.amazonaws.com"
#        }
#      },
#    ]
#  })
#
#  tags = local.tags
#}

###############################################################################
# STS - ServiceAccount/IRSA
###############################################################################

data "aws_iam_policy_document" "eks_assume_role_policy" {
  statement {
    sid    = "EKSAssumeRole"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "Service"
      identifiers = [
        "eks.amazonaws.com"
      ]
    }
  }
}

# argocd
data "aws_iam_policy_document" "argocd_repo_assume_role_policy" {
  source_policy_documents = [
    data.aws_iam_policy_document.eks_assume_role_policy.json
  ]

  statement {
    sid    = "ArgoCDRepoAssumeRoleWithWebIdentity"
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    principals {
      type = "Federated"
      identifiers = [
        module.eks.oidc_provider_arn
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values = [
        "system:serviceaccount:argocd:argocd-repo-server" # "namespace:service-account-name"
      ]
    }
  }
}

resource "aws_iam_role" "argocd_repo" {
  name               = "ArgoCDrepoRole"
  assume_role_policy = data.aws_iam_policy_document.argocd_repo_assume_role_policy.json
}

# argocd image updater
data "aws_iam_policy_document" "argocd_image_updater_assume_role_policy" {
  source_policy_documents = [
    data.aws_iam_policy_document.eks_assume_role_policy.json
  ]

  statement {
    sid    = "ArgoCDImageUpdaterAssumeRoleWithWebIdentity"
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    principals {
      type = "Federated"
      identifiers = [
        module.eks.oidc_provider_arn
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values = [
        "system:serviceaccount:argocd:argocd-image-updater" # "namespace:service-account-name"
      ]
    }
  }
}

resource "aws_iam_role" "argocd_image_updater" {
  name               = "ImageUpdaterRole"
  assume_role_policy = data.aws_iam_policy_document.argocd_image_updater_assume_role_policy.json
}

# prometheus
data "aws_iam_policy_document" "prometheus_assume_role_policy" {
  source_policy_documents = [
    data.aws_iam_policy_document.eks_assume_role_policy.json
  ]

  statement {
    sid    = "PrometheusAssumeRoleWithWebIdentity"
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    principals {
      type = "Federated"
      identifiers = [
        module.eks.oidc_provider_arn
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values = [
        "system:serviceaccount:prometheus:kube-prometheus-stack-grafana" # "namespace:service-account-name"
      ]
    }
  }
}

resource "aws_iam_role" "prometheus" {
  name               = "PrometheusRole"
  assume_role_policy = data.aws_iam_policy_document.prometheus_assume_role_policy.json
}

# sonarqube
data "aws_iam_policy_document" "sonarqube_assume_role_policy" {
  source_policy_documents = [
    data.aws_iam_policy_document.eks_assume_role_policy.json
  ]

  statement {
    sid    = "SonarqubeAssumeRoleWithWebIdentity"
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    principals {
      type = "Federated"
      identifiers = [
        module.eks.oidc_provider_arn
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values = [
        "system:serviceaccount:sonarqube:sonarqube" # "namespace:service-account-name"
      ]
    }
  }
}
