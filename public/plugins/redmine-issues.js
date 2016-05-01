(function() {
	'use strict';

	angular.module('StatusDashboard').directive('redmineIssues', [
		'statusService',
		function(statusService) {
			return {
				restrict:    'E',
				link :       function(scope, element, attrs) {
					scope.chartLabels = [];
					scope.chartSeries = [];
					scope.chartData = [ [] ];
					scope.statusStats = [];
					scope.chartOptions = {
						scales : {
							xAxes : [ {
								stacked : true
							} ],
							yAxes : [ {
								stacked : true
							} ]
						}
					};

					scope.$watch(
						function() {
							return statusService.getStatus(scope.statusId)
						},
						function(newValue, oldValue) {
							if (newValue === null) {
								return;
							}
							console.log("Old: ", oldValue, "New: ", newValue);

							var statusStats = {};
							var trackers = {};
							newValue.issues.forEach(function(issue) {
								if (!statusStats[issue.status.id]) {
									statusStats[issue.status.id] = {
										id : issue.status.id,
										name : issue.status.name,
										count : 0,
										tracker : {}
									};
									scope.statusStats.push(statusStats[issue.status.id]);
								}
								if (!statusStats[issue.status.id].tracker[issue.tracker.id]) {
									statusStats[issue.status.id].tracker[issue.tracker.id] = {
										id : issue.tracker.id,
										name : issue.tracker.name,
										count : 0
									}
								}
								statusStats[issue.status.id].count++;
								statusStats[issue.status.id].tracker[issue.tracker.id].count++;
								if (!trackers[issue.tracker.id]) {
									trackers[issue.tracker.id] = {
										name : issue.tracker.name,
										id : issue.tracker.id
									};
								}
							});
							var trackerList = [];
							Object.keys(trackers).forEach(function(trackerId) {
								trackerList.push(trackers[trackerId]);
							});
							trackerList.sort(function(a, b) {
								return a.name.localeCompare(b.name);
							});
							scope.chartSeries = trackerList.map(function(tracker) {
								return tracker.name;
							});
							scope.chartLabels.length = 0;
							scope.chartData[0].length = 0;
							scope.statusStats.forEach(function(statusType) {
								scope.chartLabels.push(statusType.name);
								trackerList.forEach(function(tracker, index) {
									if (!scope.chartData[index]) {
										scope.chartData[index] = [];
									}
									scope.chartData[index].push(
										statusType.tracker[tracker.id]
											? statusType.tracker[tracker.id].count
											: 0
									);
								})
							});
							scope.issueCount = newValue.issues.length;
						}
					);
				},
				replace:     false,
				templateUrl: 'plugins/templates/redmine-issues.html',
				scope:       {
					statusId:    '@statusId',
					titleSuffix: '@titleSuffix'
				}
			}
		}
	]).directive('redmineIssuesList', [
		'statusService',
		function(statusService) {
			return {
				restrict:    'E',
				link :       function(scope, element, attrs) {
					scope.latest = [];

					scope.$watch(
						function() {
							return statusService.getStatus(scope.statusId)
						},
						function(newValue, oldValue) {
							if (newValue === null) {
								return;
							}
							scope.issues = newValue.issues;
						}
					);
					scope.$watch('trackerClassStr', function (newValue, oldValue) {
						scope.trackerClass = scope.$eval(newValue);
					});
					scope.$watch('priorityClassStr', function (newValue, oldValue) {
						scope.priorityClass = scope.$eval(newValue);
					});
					scope.$watch('statusClassStr', function (newValue, oldValue) {
						scope.statusClass = scope.$eval(newValue);
					});
					scope.$watch('reverseStr', function (newValue, oldValue) {
						scope.reverse = (newValue === null || newValue === undefined)
							? true
							: scope.$eval(newValue);
					});
				},
				replace:     false,
				templateUrl: 'plugins/templates/redmine-issues-list.html',
				scope:       {
					statusId:         '@statusId',
					titleSuffix:      '@titleSuffix',
					count:            '@count',
					orderBy:          '@orderBy',
					reverseStr:       '@reverse',
					trackerClassStr:  '@trackerClass',
					priorityClassStr: '@priorityClass',
					statusClassStr:   '@statusClass'
				}
			}
		}
	]);
}());
