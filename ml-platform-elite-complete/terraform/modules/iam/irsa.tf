resource "aws_iam_role" "training_role" {
  name = "ml-training-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = "eks.amazonaws.com"
        },
        Action = "sts:AssumeRoleWithWebIdentity"
      }
    ]
  })
}

resource "aws_iam_policy" "training_policy" {
  name = "ml-training-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["s3:GetObject"],
        Resource = "arn:aws:s3:::ml-data-bucket/*"
      },
      {
        Effect = "Allow",
        Action = ["s3:PutObject"],
        Resource = "arn:aws:s3:::ml-model-registry/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "training_attach" {
  role       = aws_iam_role.training_role.name
  policy_arn = aws_iam_policy.training_policy.arn
}
