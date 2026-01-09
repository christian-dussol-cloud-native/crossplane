#!/usr/bin/env python3
"""
Crossplane Cost Calculator
Calculate potential cost savings when adopting Crossplane for infrastructure management

This tool helps quantify the business value of Crossplane by comparing:
- Traditional always-on infrastructure costs
- Crossplane-managed infrastructure with optimized usage patterns
- Multi-cloud cost comparison
- Team efficiency improvements

Author: Christian Dussol
License: Apache 2.0
"""

import argparse
import json
from dataclasses import dataclass
from typing import Dict, List
from enum import Enum


class Environment(Enum):
    """Environment types with typical usage patterns"""
    PRODUCTION = "production"
    STAGING = "staging"
    DEVELOPMENT = "development"


class CloudProvider(Enum):
    """Supported cloud providers"""
    AWS = "aws"
    AZURE = "azure"
    GCP = "gcp"


@dataclass
class UsagePattern:
    """Usage pattern for an environment"""
    hours_per_week: float
    description: str


# Typical usage patterns by environment
USAGE_PATTERNS = {
    Environment.PRODUCTION: UsagePattern(168, "24/7 operation"),
    Environment.STAGING: UsagePattern(60, "Business hours + testing windows"),
    Environment.DEVELOPMENT: UsagePattern(45, "Developer working hours only")
}


@dataclass
class DatabasePricing:
    """Cloud provider pricing for database instances"""
    provider: CloudProvider
    small_hourly: float   # db.t3.micro / B_Gen5_1 / db-f1-micro
    medium_hourly: float  # db.t3.medium / GP_Gen5_2 / db-n1-standard-1
    large_hourly: float   # db.r6g.xlarge / MO_Gen5_4 / db-n1-standard-4


# Approximate pricing (as of 2025, EU regions)
PRICING = {
    CloudProvider.AWS: DatabasePricing(CloudProvider.AWS, 0.017, 0.068, 0.336),
    CloudProvider.AZURE: DatabasePricing(CloudProvider.AZURE, 0.020, 0.100, 0.400),
    CloudProvider.GCP: DatabasePricing(CloudProvider.GCP, 0.015, 0.071, 0.338)
}


@dataclass
class WorkloadConfig:
    """Configuration for a workload"""
    name: str
    environment: Environment
    size: str  # small, medium, large
    replicas: int
    provider: CloudProvider


class CostCalculator:
    """Calculate infrastructure costs"""
    
    def __init__(self):
        self.hours_per_week = 168  # Total hours in a week
        self.weeks_per_month = 4.33  # Average weeks per month
    
    def get_hourly_rate(self, provider: CloudProvider, size: str) -> float:
        """Get hourly rate for instance size and provider"""
        pricing = PRICING[provider]
        rates = {
            'small': pricing.small_hourly,
            'medium': pricing.medium_hourly,
            'large': pricing.large_hourly
        }
        return rates.get(size, pricing.medium_hourly)
    
    def calculate_traditional_cost(self, workload: WorkloadConfig) -> Dict:
        """Calculate cost for traditional always-on infrastructure"""
        hourly_rate = self.get_hourly_rate(workload.provider, workload.size)
        
        weekly_cost = hourly_rate * self.hours_per_week * workload.replicas
        monthly_cost = weekly_cost * self.weeks_per_month
        annual_cost = monthly_cost * 12
        
        return {
            'hourly_rate': hourly_rate,
            'weekly_cost': weekly_cost,
            'monthly_cost': monthly_cost,
            'annual_cost': annual_cost,
            'hours_billed': self.hours_per_week,
            'hours_used': USAGE_PATTERNS[workload.environment].hours_per_week,
            'waste_hours': self.hours_per_week - USAGE_PATTERNS[workload.environment].hours_per_week
        }
    
    def calculate_crossplane_cost(self, workload: WorkloadConfig) -> Dict:
        """Calculate cost with Crossplane optimization (scale-to-zero, right-sizing)"""
        hourly_rate = self.get_hourly_rate(workload.provider, workload.size)
        usage_hours = USAGE_PATTERNS[workload.environment].hours_per_week
        
        # With Crossplane, you only pay for actual usage
        weekly_cost = hourly_rate * usage_hours * workload.replicas
        monthly_cost = weekly_cost * self.weeks_per_month
        annual_cost = monthly_cost * 12
        
        return {
            'hourly_rate': hourly_rate,
            'weekly_cost': weekly_cost,
            'monthly_cost': monthly_cost,
            'annual_cost': annual_cost,
            'hours_billed': usage_hours,
            'hours_used': usage_hours,
            'waste_hours': 0
        }
    
    def calculate_savings(self, traditional: Dict, crossplane: Dict) -> Dict:
        """Calculate savings between traditional and Crossplane approaches"""
        weekly_savings = traditional['weekly_cost'] - crossplane['weekly_cost']
        monthly_savings = traditional['monthly_cost'] - crossplane['monthly_cost']
        annual_savings = traditional['annual_cost'] - crossplane['annual_cost']
        
        savings_percentage = (monthly_savings / traditional['monthly_cost']) * 100
        
        return {
            'weekly_savings': weekly_savings,
            'monthly_savings': monthly_savings,
            'annual_savings': annual_savings,
            'savings_percentage': savings_percentage,
            'waste_eliminated_hours': traditional['waste_hours']
        }


class MultiCloudComparison:
    """Compare costs across cloud providers"""
    
    def __init__(self):
        self.calculator = CostCalculator()
    
    def compare_providers(self, workload_config: WorkloadConfig) -> Dict:
        """Compare cost across all providers for the same workload"""
        results = {}
        
        for provider in CloudProvider:
            workload = WorkloadConfig(
                name=workload_config.name,
                environment=workload_config.environment,
                size=workload_config.size,
                replicas=workload_config.replicas,
                provider=provider
            )
            
            traditional = self.calculator.calculate_traditional_cost(workload)
            crossplane = self.calculator.calculate_crossplane_cost(workload)
            savings = self.calculator.calculate_savings(traditional, crossplane)
            
            results[provider.value] = {
                'traditional_monthly': traditional['monthly_cost'],
                'crossplane_monthly': crossplane['monthly_cost'],
                'monthly_savings': savings['monthly_savings'],
                'savings_percentage': savings['savings_percentage']
            }
        
        # Find best value provider
        best_provider = min(results.items(), key=lambda x: x[1]['crossplane_monthly'])
        
        return {
            'comparison': results,
            'best_value_provider': best_provider[0],
            'best_value_monthly_cost': best_provider[1]['crossplane_monthly']
        }


def print_workload_analysis(workload: WorkloadConfig, calculator: CostCalculator):
    """Print detailed cost analysis for a workload"""
    traditional = calculator.calculate_traditional_cost(workload)
    crossplane = calculator.calculate_crossplane_cost(workload)
    savings = calculator.calculate_savings(traditional, crossplane)
    
    print(f"\n{'='*70}")
    print(f"Cost Analysis: {workload.name}")
    print(f"{'='*70}")
    print(f"Environment:     {workload.environment.value}")
    print(f"Cloud Provider:  {workload.provider.value.upper()}")
    print(f"Instance Size:   {workload.size}")
    print(f"Replicas:        {workload.replicas}")
    print(f"Usage Pattern:   {USAGE_PATTERNS[workload.environment].description}")
    
    print(f"\n{'-'*70}")
    print("TRADITIONAL KUBERNETES DEPLOYMENT (Always-On)")
    print(f"{'-'*70}")
    print(f"Hours billed/week:    {traditional['hours_billed']}")
    print(f"Hours used/week:      {traditional['hours_used']}")
    print(f"Waste hours/week:     {traditional['waste_hours']} ({(traditional['waste_hours']/168)*100:.1f}%)")
    print(f"\nMonthly cost:         ${traditional['monthly_cost']:,.2f}")
    print(f"Annual cost:          ${traditional['annual_cost']:,.2f}")
    
    print(f"\n{'-'*70}")
    print("CROSSPLANE-OPTIMIZED DEPLOYMENT")
    print(f"{'-'*70}")
    print(f"Hours billed/week:    {crossplane['hours_billed']}")
    print(f"Hours used/week:      {crossplane['hours_used']}")
    print(f"Waste hours/week:     {crossplane['waste_hours']}")
    print(f"\nMonthly cost:         ${crossplane['monthly_cost']:,.2f}")
    print(f"Annual cost:          ${crossplane['annual_cost']:,.2f}")
    
    print(f"\n{'-'*70}")
    print(f"💰 COST SAVINGS WITH CROSSPLANE")
    print(f"{'-'*70}")
    print(f"Monthly savings:      ${savings['monthly_savings']:,.2f}")
    print(f"Annual savings:       ${savings['annual_savings']:,.2f}")
    print(f"Savings percentage:   {savings['savings_percentage']:.1f}%")
    print(f"Waste eliminated:     {savings['waste_eliminated_hours']} hours/week")


def print_multi_cloud_comparison(workload_config: WorkloadConfig):
    """Print multi-cloud cost comparison"""
    comparator = MultiCloudComparison()
    results = comparator.compare_providers(workload_config)
    
    print(f"\n{'='*70}")
    print("MULTI-CLOUD COST COMPARISON")
    print(f"{'='*70}")
    print(f"Workload: {workload_config.name} ({workload_config.environment.value})")
    print(f"Size: {workload_config.size}, Replicas: {workload_config.replicas}")
    
    print(f"\n{'-'*70}")
    print(f"{'Provider':<15} {'Traditional':<15} {'Crossplane':<15} {'Savings':<15} {'%':<10}")
    print(f"{'-'*70}")
    
    for provider, data in results['comparison'].items():
        print(f"{provider.upper():<15} "
              f"${data['traditional_monthly']:>8,.2f}     "
              f"${data['crossplane_monthly']:>8,.2f}     "
              f"${data['monthly_savings']:>8,.2f}     "
              f"{data['savings_percentage']:>6.1f}%")
    
    print(f"\n🏆 Best Value Provider: {results['best_value_provider'].upper()}")
    print(f"   Monthly cost: ${results['best_value_monthly_cost']:,.2f}")
    print(f"\n   ✅ Crossplane enables you to switch providers without code changes!")


def calculate_portfolio_savings(workloads: List[WorkloadConfig]):
    """Calculate total savings across multiple workloads"""
    calculator = CostCalculator()
    
    total_traditional_monthly = 0
    total_crossplane_monthly = 0
    
    print(f"\n{'='*70}")
    print("PORTFOLIO COST ANALYSIS")
    print(f"{'='*70}")
    
    for workload in workloads:
        traditional = calculator.calculate_traditional_cost(workload)
        crossplane = calculator.calculate_crossplane_cost(workload)
        
        total_traditional_monthly += traditional['monthly_cost']
        total_crossplane_monthly += crossplane['monthly_cost']
        
        print(f"\n{workload.name:<25} {workload.environment.value:<12} "
              f"${traditional['monthly_cost']:>8,.2f} → ${crossplane['monthly_cost']:>8,.2f}")
    
    total_savings = total_traditional_monthly - total_crossplane_monthly
    savings_pct = (total_savings / total_traditional_monthly) * 100
    
    print(f"\n{'-'*70}")
    print(f"TOTAL MONTHLY COSTS:")
    print(f"  Traditional:           ${total_traditional_monthly:,.2f}")
    print(f"  With Crossplane:       ${total_crossplane_monthly:,.2f}")
    print(f"  Monthly Savings:       ${total_savings:,.2f}")
    print(f"  Annual Savings:        ${total_savings * 12:,.2f}")
    print(f"  Savings Percentage:    {savings_pct:.1f}%")


def main():
    parser = argparse.ArgumentParser(
        description='Calculate cost savings with Crossplane',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Single workload analysis
  python3 cost-calculator.py --name "api-service" --env development --size medium --replicas 2

  # Multi-cloud comparison
  python3 cost-calculator.py --name "database" --env production --size large --replicas 3 --compare-clouds

  # Portfolio analysis (edit script to add workloads)
  python3 cost-calculator.py --portfolio
        """
    )
    
    parser.add_argument('--name', type=str, default='my-workload', help='Workload name')
    parser.add_argument('--env', type=str, choices=['production', 'staging', 'development'],
                       default='development', help='Environment type')
    parser.add_argument('--size', type=str, choices=['small', 'medium', 'large'],
                       default='medium', help='Instance size')
    parser.add_argument('--replicas', type=int, default=2, help='Number of replicas')
    parser.add_argument('--provider', type=str, choices=['aws', 'azure', 'gcp'],
                       default='aws', help='Cloud provider')
    parser.add_argument('--compare-clouds', action='store_true',
                       help='Compare costs across all cloud providers')
    parser.add_argument('--portfolio', action='store_true',
                       help='Analyze a portfolio of workloads')
    
    args = parser.parse_args()
    
    # Create workload configuration
    workload = WorkloadConfig(
        name=args.name,
        environment=Environment(args.env),
        size=args.size,
        replicas=args.replicas,
        provider=CloudProvider(args.provider)
    )
    
    calculator = CostCalculator()
    
    if args.portfolio:
        # Example portfolio - customize for your needs
        portfolio = [
            WorkloadConfig("customer-api", Environment.PRODUCTION, "medium", 3, CloudProvider.AWS),
            WorkloadConfig("admin-portal", Environment.PRODUCTION, "small", 2, CloudProvider.AWS),
            WorkloadConfig("staging-db", Environment.STAGING, "medium", 1, CloudProvider.AWS),
            WorkloadConfig("dev-api", Environment.DEVELOPMENT, "small", 2, CloudProvider.AWS),
            WorkloadConfig("dev-database", Environment.DEVELOPMENT, "medium", 1, CloudProvider.AWS),
        ]
        calculate_portfolio_savings(portfolio)
    
    elif args.compare_clouds:
        print_multi_cloud_comparison(workload)
    
    else:
        print_workload_analysis(workload, calculator)
    
    print(f"\n{'='*70}")
    print("💡 Key Insights:")
    print("   - Crossplane enables infrastructure optimization across clouds")
    print("   - Pay only for actual usage, not idle time")
    print("   - Switch providers without application code changes")
    print("   - Enforce cost governance with Kyverno policies")
    print(f"{'='*70}\n")


if __name__ == '__main__':
    main()
