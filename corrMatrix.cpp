// File: corrMatrix.cpp
#include <Rcpp.h>
using namespace Rcpp;

// Function to compute the mean of a vector
double computeMean(NumericVector x) {
  int n = x.size();
  double sum = 0.0;
  for(int i = 0; i < n; ++i) {
    sum += x[i];
  }
  return sum / n;
}

// Function to compute the correlation between two vectors
double computeCorrelation(NumericVector x, NumericVector y) {
  int n = x.size();
  double mean_x = computeMean(x);
  double mean_y = computeMean(y);
  double sum_xy = 0.0;
  double sum_x_squared = 0.0;
  double sum_y_squared = 0.0;
  for(int i = 0; i < n; ++i) {
    sum_xy += (x[i] - mean_x) * (y[i] - mean_y);
    sum_x_squared += pow(x[i] - mean_x, 2);
    sum_y_squared += pow(y[i] - mean_y, 2);
  }
  return sum_xy / sqrt(sum_x_squared * sum_y_squared);
}

// Function to compute the correlation matrix
NumericMatrix computeCorrelationMatrix(NumericMatrix mat) {
  int ncol = mat.ncol();
  NumericMatrix corrMatrix(ncol, ncol);
  for(int i = 0; i < ncol; ++i) {
    for(int j = i; j < ncol; ++j) {
      double corr = computeCorrelation(mat(_, i), mat(_, j));
      corrMatrix(i, j) = corr;
      corrMatrix(j, i) = corr; // because correlation matrix is symmetric
    }
  }
  return corrMatrix;
}

// [[Rcpp::export]]
NumericMatrix corrMatrix(NumericMatrix mat) {
  NumericMatrix corrMatrix = computeCorrelationMatrix(mat);
  
  // Get column names from the input matrix
  CharacterVector colNames = colnames(mat);
  
  // Set column names and row names to the resulting correlation matrix
  colnames(corrMatrix) = colNames;
  rownames(corrMatrix) = colNames;
  
  return corrMatrix;
}
