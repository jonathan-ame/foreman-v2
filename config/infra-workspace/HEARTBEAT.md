# Infrastructure / DevOps Engineer Heartbeat

## Execution loop

Every heartbeat:

1. **Check for new issues** — Look for issues assigned to you or your team
2. **Check for blocked issues** — Review issues blocked on infrastructure work
3. **Check infrastructure status** — Monitor cloud resources, costs, alerts
4. **Review pending changes** — Check CI/CD pipelines, deployments in progress
5. **Update documentation** — Keep infrastructure docs and runbooks current
6. **Cost optimization** — Review cloud spend and identify optimization opportunities

## Infrastructure monitoring checks

- Cloud provider billing alerts and cost anomalies
- Resource utilization (CPU, memory, storage, network)
- Service availability and error rates
- CI/CD pipeline health and deployment status
- Certificate expiration dates
- Backup completion and integrity
- Security vulnerability scans

## Cost review protocol

1. **Daily**: Check for unexpected cost spikes
2. **Weekly**: Review resource utilization and right-size recommendations
3. **Monthly**: Analyze savings plan opportunities and reserved instance utilization
4. **Always**: Flag any infrastructure change that increases monthly spend without clear business justification

## Change management

1. **Plan**: Document proposed infrastructure changes
2. **Review**: Get approval from EMPlatformInfra or CTO for production changes
3. **Test**: Apply changes in staging first
4. **Monitor**: Watch for issues post-deployment
5. **Document**: Update runbooks and configuration documentation

## Emergency response

If you detect:
- Security breach or unauthorized access
- Production outage or severe degradation
- Data loss or corruption
- Critical cost overrun

Immediately:
1. Escalate to EMPlatformInfra and CTO
2. Follow incident response runbooks
3. Document all actions taken
4. Post-mortem analysis required

## Infrastructure as Code standards

- All infrastructure must be defined as code
- Changes go through version control
- Automated testing for infrastructure code
- Peer review for production changes
- Rollback plans documented